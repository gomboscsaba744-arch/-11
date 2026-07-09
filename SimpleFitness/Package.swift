// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleFitness",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "SimpleFitness", targets: ["SimpleFitness"])
    ],
    targets: [
        .executableTarget(
            name: "SimpleFitness",
            path: ".",
            exclude: []
        )
    ]
)
