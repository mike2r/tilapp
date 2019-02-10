import FluentPostgreSQL
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())
    try services.register(AuthenticationProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    // Add fluent commands
    var commands = CommandConfig.default()
    commands.useFluentCommands()
    services.register(commands)
        
    // Configure a PostgreSQL database
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "kalanieast.cifrahp0izue.us-east-1.rds.amazonaws.com"
    let username = Environment.get("DATABASE_USER") ?? "mrruch"
    let databaseName = Environment.get("DATABASE_DB") ?? "tilapp"
    let password = Environment.get("DATABASE_PASSWORD") ?? "4fitness"
    let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname,
                                                  username: username,
                                                  database: databaseName,
                                                  password: password)

    /// Register the configured PostgreSQL database to the database config.
    let database = PostgreSQLDatabase(config: databaseConfig)
    var databases = DatabasesConfig()
    databases.add(database: database, as: .psql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: AcronymCategoryPivot.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    migrations.add(migration: AdminUser.self, database: .psql)
    // migrations.add(migration: AddUserPassword.self, database: .psql)
    services.register(migrations)
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)

}
