import AppKit
import Darwin
import Foundation

/// States surfaced by the settings row and the status menu.
enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case available(String)
    case downloading
    case installing
    case failed(String)
}

struct LatestRelease: Sendable {
    let version: String
    let zipURL: URL
}

/// Lightweight self-updater on top of GitHub Releases: fetch the latest
/// release, download the .zip asset, and swap the running bundle via a small
/// detached shell script that waits for this process to exit.
///
/// Sparkle was deliberately skipped — the release pipeline already publishes
/// zips, the app is not sandboxed, and a ~2 MB download needs no deltas.
enum AppUpdater {
    static let repo = "zycFrancis/coding-quota-bar"

    /// Self-update only makes sense when running from a real .app bundle.
    static var canSelfUpdate: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
            && Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") != nil
    }

    // MARK: - Checking

    static func fetchLatestRelease() async throws -> LatestRelease {
        let apiURL = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        var request = URLRequest(url: apiURL)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw UpdateError.http(status)
        }
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tag = object["tag_name"] as? String
        else {
            throw UpdateError.malformedResponse
        }

        let assets = (object["assets"] as? [[String: Any]]) ?? []
        let zipAsset = assets.first { asset in
            guard let name = asset["name"] as? String else { return false }
            return name.hasPrefix("Quota-Bar-") && name.hasSuffix(".zip")
        }
        guard
            let zipAsset,
            let urlString = zipAsset["browser_download_url"] as? String,
            let zipURL = URL(string: urlString)
        else {
            throw UpdateError.zipAssetMissing
        }
        return LatestRelease(version: tag.trimmingCharacters(in: CharacterSet(charactersIn: "v ")), zipURL: zipURL)
    }

    /// Component-wise semver-ish comparison: 1.10.0 > 1.9.1 > 1.9.
    /// Tolerates a leading "v" (GitHub tags) and suffixes like "-beta.1".
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let left = numericComponents(candidate)
        let right = numericComponents(current)
        for index in 0..<max(left.count, right.count) {
            let l = index < left.count ? left[index] : 0
            let r = index < right.count ? right[index] : 0
            if l != r { return l > r }
        }
        return false
    }

    private static func numericComponents(_ version: String) -> [Int] {
        version
            .drop(while: { !$0.isNumber })
            .split(separator: ".")
            .map { Int($0.prefix(while: \.isNumber)) ?? 0 }
    }

    // MARK: - Download & stage

    static func downloadAndStage(_ release: LatestRelease) async throws -> URL {
        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuotaBarUpdate", isDirectory: true)
        try? FileManager.default.removeItem(at: workDir)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)

        let zipDestination = workDir.appendingPathComponent("update.zip")
        let (data, response) = try await URLSession.shared.data(from: release.zipURL)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status), !data.isEmpty else {
            throw UpdateError.http(status)
        }
        try data.write(to: zipDestination, options: .atomic)

        let payloadDir = workDir.appendingPathComponent("payload", isDirectory: true)
        try FileManager.default.createDirectory(at: payloadDir, withIntermediateDirectories: true)
        try runProcess("/usr/bin/ditto", arguments: ["-x", "-k", zipDestination.path, payloadDir.path])

        let stagedApp = payloadDir.appendingPathComponent("Quota Bar.app", isDirectory: true)
        guard
            FileManager.default.fileExists(
                atPath: stagedApp.appendingPathComponent("Contents/MacOS/QuotaBar").path
            )
        else {
            throw UpdateError.stagedBundleInvalid
        }
        return stagedApp
    }

    // MARK: - Swap & relaunch

    /// Writes a tiny script that waits for this process to exit, swaps the
    /// bundles (old one kept as `<path>.old` until the new one launches) and
    /// reopens the app. The script runs detached, so terminating afterwards is
    /// safe.
    static func swapAndRelaunch(stagedAppURL: URL) throws {
        let currentURL = Bundle.main.bundleURL
        let backupURL = currentURL.appendingPathExtension("old")
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuotaBarUpdate/swap.sh")

        let script = """
        #!/bin/sh
        # Wait for the running app to exit so the bundle is not in use.
        while kill -0 "$1" 2>/dev/null; do sleep 0.3; done
        rm -rf "$4"
        if mv "$2" "$4"; then
            if mv "$3" "$2"; then
                open "$2"
                sleep 3
                rm -rf "$4"
                exit 0
            fi
            mv "$4" "$2"
        fi
        exit 1
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        chmod(scriptURL.path, S_IRUSR | S_IWUSR | S_IXUSR)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            scriptURL.path,
            String(getpid()),
            currentURL.path,
            stagedAppURL.path,
            backupURL.path
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    private static func runProcess(_ executablePath: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw UpdateError.helperFailed(executablePath)
        }
    }
}

enum UpdateError: LocalizedError {
    case http(Int)
    case malformedResponse
    case zipAssetMissing
    case stagedBundleInvalid
    case helperFailed(String)

    var errorDescription: String? {
        switch self {
        case .http(let status):
            "GitHub 返回 HTTP \(status)"
        case .malformedResponse:
            "GitHub Release 数据无法识别"
        case .zipAssetMissing:
            "最新 Release 里没有找到可下载的 zip 包"
        case .stagedBundleInvalid:
            "下载的更新包内容不完整"
        case .helperFailed(let tool):
            "更新助手执行失败：\(tool)"
        }
    }
}
