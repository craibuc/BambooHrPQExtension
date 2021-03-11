// This file contains your Data Connector logic
section BambooHrPQExtension;

[DataSource.Kind="BambooHrPQExtension", Publish="BambooHrPQExtension.Publish"]
shared BambooHrPQExtension.Contents = (optional message as text) =>
    let
        _message = if (message <> null) then message else "(no message)",
        a = "Hello from BambooHrPQExtension: " & _message
    in
        a;

// Data Source Kind description
BambooHrPQExtension = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
BambooHrPQExtension.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = BambooHrPQExtension.Icons,
    SourceTypeImage = BambooHrPQExtension.Icons
];

BambooHrPQExtension.Icons = [
    Icon16 = { Extension.Contents("BambooHrPQExtension16.png"), Extension.Contents("BambooHrPQExtension20.png"), Extension.Contents("BambooHrPQExtension24.png"), Extension.Contents("BambooHrPQExtension32.png") },
    Icon32 = { Extension.Contents("BambooHrPQExtension32.png"), Extension.Contents("BambooHrPQExtension40.png"), Extension.Contents("BambooHrPQExtension48.png"), Extension.Contents("BambooHrPQExtension64.png") }
];
