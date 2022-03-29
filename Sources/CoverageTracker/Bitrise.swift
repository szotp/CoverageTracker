//
//  File.swift
//  
//
//  Created by pszot on 27/03/2022.
//

import Foundation

/// https://devcenter.bitrise.io/en/references/available-environment-variables.html
/// https://devcenter.bitrise.io/en/api/api-reference.html#api-reference
class BitriseApi {
    let session: URLSession
    let token: String
    let decoder = JSONDecoder()
    
    init(token: String) {
        self.token = token
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization": token]
        session = URLSession(configuration: configuration)
    }
    
    func getBuilds(appSlug: String) async throws -> BitriseResponse<[Build]> {
        let url = URL(string: "https://api.bitrise.io/v0.1/apps/\(appSlug)/builds?sort_by=created_at&status=1")!
        let data = try await session.data(from: url).0
        return try decoder.decode(BitriseResponse<[Build]>.self, from: data)
    }
    
    func getArtifacts(appSlug: String, buildSlug: String) async throws -> BitriseResponse<[Artifact]> {
        let url = URL(string: "https://api.bitrise.io/v0.1/apps/\(appSlug)/builds/\(buildSlug)/artifacts")!
        let data = try await session.data(from: url).0
        return try decoder.decode(BitriseResponse<[Artifact]>.self, from: data)
    }
    
    func getArtifact(appSlug: String, buildSlug: String, artifactSlug: String) async throws -> BitriseResponse<ArtifactFull> {
        let url = URL(string: "https://api.bitrise.io/v0.1/apps/\(appSlug)/builds/\(buildSlug)/artifacts/\(artifactSlug)")!
        let data = try await session.data(from: url).0
        return try decoder.decode(BitriseResponse<ArtifactFull>.self, from: data)
    }
    
    struct Build: Codable {
        let slug: String
        let commit_hash: String?
        let pull_request_target_branch: String?
    }
    
    struct Artifact: Codable {
        let slug: String
        let title: String
    }
    
    struct ArtifactFull: Codable {
        let expiring_download_url: URL
    }
}

struct BitriseResponse<T: Codable>: Codable {
    var data: T
}

enum Errors: Error {
    case notFound
}

func downloadPreviousArtifact(title: String) async throws -> URL {
    let api = BitriseApi(token: environment.token)
    let git = Git()
    let builds = try await api.getBuilds(appSlug: environment.appSlug).data
    let resultURL = URL(fileURLWithPath: "previous_artifacts/\(title)")
    
    if files.fileExists(atPath: resultURL.path) {
        return resultURL
    }
    
    for build in builds {
        guard let hash = build.commit_hash else {
            continue
        }
        
        if git.currentBranchHasCommit(hash: hash) {
            let artifacts = try await api.getArtifacts(appSlug: environment.appSlug, buildSlug: build.slug).data
            
            for artifact in artifacts {
                if artifact.title == "\(title).zip" {
                    let url = try await api.getArtifact(appSlug: environment.appSlug, buildSlug: build.slug, artifactSlug: artifact.slug).data.expiring_download_url
                    try ShellTask("rm -rf previous_artifacts").wait()
                    try ShellTask("mkdir previous_artifacts").wait()
                    try ShellTask("curl \"\(url)\" > previous_artifacts/\(artifact.title)").wait()
                    
                    try ShellTask("unzip \(artifact.title)", currentDirectory: "previous_artifacts").wait()
                    return URL(fileURLWithPath: "previous_artifacts/\(title)")
                }
            }
        }
    }
    
    throw Errors.notFound
}


private extension URLSession {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}
