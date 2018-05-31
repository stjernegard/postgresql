import Foundation
import NIOOpenSSL

/// Config options for a `PostgreSQLConnection`
public struct PostgreSQLDatabaseConfig {
    /// Creates a `PostgreSQLDatabaseConfig` with default settings.
    public static func `default`() -> PostgreSQLDatabaseConfig {
        return .init(hostname: "localhost", port: 5432, username: "postgres")
    }
    
    /// Specifies how to connect to a PostgreSQL server.
    public enum ServerAddress {
        /// Connect via TCP using the given hostname and port.
        case tcp(hostname: String, port: Int)
        /// Connect via a Unix domain socket file.
        case unixSocket(path: String)
        
        public static let `default` = ServerAddress.tcp(hostname: "localhost", port: 5432)
        public static let socketDefault = ServerAddress.unixSocket(path: "/tmp/.s.PGSQL.5432")
    }
    
    /// Which server to connect to.
    public let serverAddress: ServerAddress

    /// Username to authenticate.
    public let username: String
    
    /// Optional database name to use during authentication.
    /// Defaults to the username.
    public let database: String?
    
    /// Optional password to use for authentication.
    public let password: String?
    
    /// Configures how data is transported to the server. Use this to enable SSL.
    /// See `PostgreSQLTransportConfig` for more info
    public let transportConfig: PostgreSQLTransportConfig
    
    /// Creates a new `PostgreSQLDatabaseConfig`.
	public init(serverAddress: ServerAddress, username: String, database: String? = nil, password: String? = nil, transport: PostgreSQLTransportConfig = .cleartext) {
		self.serverAddress = serverAddress
		self.username = username
		self.database = database
		self.password = password
		self.transportConfig = transport
	}
	
	public init(hostname: String, port: Int = 5432, username: String, database: String? = nil, password: String? = nil, transport: PostgreSQLTransportConfig = .cleartext) {
		self.init(serverAddress: .tcp(hostname: hostname, port: port), username: username, database: database, password: password, transport: transport)
	}

    /// Creates a `PostgreSQLDatabaseConfig` frome a connection string.
    public init(url urlString: String, transport: PostgreSQLTransportConfig = .cleartext) throws {
        guard let url = URL(string: urlString),
            let hostname = url.host,
            let port = url.port,
            let username = url.user,
            url.path.count > 0
        else {
            throw PostgreSQLError(
                identifier: "Bad Connection String",
                reason: "Host could not be parsed",
                possibleCauses: ["Foundation URL is unable to parse the provided connection string"],
                suggestedFixes: ["Check the connection string being passed"],
                source: .capture()
            )
        }
        self.serverAddress = .tcp(hostname: hostname, port: port)
        self.username = username
        let database = url.path
        if database.hasPrefix("/") {
            self.database = database.dropFirst().description
        } else {
            self.database = database
        }
        self.password = url.password
        self.transportConfig = transport
    }
}
