import ArgumentParser
import Foundation
import Ink
import System
import UniformTypeIdentifiers

@main
struct Md2HTML: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "md2h",
        abstract: "Convert Markdown to HTML and watch for changes."
    )
    
    @Argument(
        help: "The input file path.",
        transform: { arg in
            let url = URL(filePath: NSString(string: arg).expandingTildeInPath)
            guard url.pathExtension == "md" else {
                throw ValidationError("Please specify a Markdown file.")
            }
            
            guard FileManager.default.fileExists(atPath: url.path()) else {
                throw ValidationError("The file does not exist.")
            }
            
            guard FileManager.default.isReadableFile(atPath: url.path()) else {
                throw ValidationError("The specified file is not readable.")
            }
            
            return url
        }
    )
    var input: URL
    
    var hasOpenedHTMLFile: Bool = false
    
    mutating func run() async throws {
        print("Started watching \(input.path())")
        
        try await processMarkdownFile(at: input)
        
        for try await _ in makeFileChangeStream(at: input) {
            try await processMarkdownFile(at: input)
        }
        
    }
}

// TODO: TODO List
/*
 - 別ディレクトリへ移動されたら検知しない。
 必要ならmacOS限定でFSEventsを使い、パスベースでフィルタする。
 - 「対象ファイルそのもの」を監視したい場合は、
 .rename/.deleteを捕捉してFDとDispatchSourceを再作成する実装が必要。
 */
func makeFileChangeStream(at url: URL) -> AsyncThrowingStream<Void, Error> {
    AsyncThrowingStream { continuation in
        do {
            let fd = try FileDescriptor.open(
                url.deletingLastPathComponent().path(),
                .readOnly
            )
            
            // 直近のMarkdown更新日時
            var lastMdMTime: Date? = (try? FileManager.default
                .attributesOfItem(atPath: url.path()))?[.modificationDate] as? Date
            
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd.rawValue,
                eventMask: .write,
                queue: .global()
            )
            
            source.setEventHandler {
                // 対象のMarkdownファイルの更新日時と直近の更新日時を比較する
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path())
                guard
                    let mtime = attrs?[.modificationDate] as? Date,
                    lastMdMTime.map({ mtime > $0 }) ?? true
                else {
                    return
                }
                lastMdMTime = mtime
                
                continuation.yield(())
            }
            
            source.setCancelHandler {
                do {
                    try fd.close()
                } catch {
                    continuation.finish(throwing: error)
                }
                continuation.finish()
            }
            
            continuation.onTermination = { @Sendable _ in
                source.cancel()
            }
            
            source.activate()
        } catch {
            continuation.finish(throwing: error)
        }
    }
}

func processMarkdownFile(at url: URL) async throws {
    let markdownString = try String(contentsOf: url, encoding: .utf8)
    let parser = MarkdownParser()
    let htmlString = parser.parse(markdownString).html
    
    let htmlURL = url.deletingPathExtension().appendingPathExtension("html")
    
    do {
        try htmlString.write(to: htmlURL, atomically: true, encoding: .utf8)
        
        openHTMLFile(at: htmlURL)
        
        print("Updated \(htmlURL.path())")
    } catch {
        print("Failed to update \(htmlURL.path()): \(error)")
    }
}

func openHTMLFile(at url: URL) {
    do {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-g", url.path()]
        try process.run()
    } catch {
        print("Failed to open \(url): \(error)")
    }
}
