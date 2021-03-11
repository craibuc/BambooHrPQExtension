// This file contains your Data Connector logic
section BambooHrPQExtension;

shared subdomain = "";

[DataSource.Kind="BambooHrPQExtension", Publish="BambooHrPQExtension.Publish"]
shared BambooHrPQExtension.Contents = (optional subdomain as text) =>
    let
        source = NavigationTable(subdomain)
    in
        source
;

/*
Purpose:
    Return tables and other objects that will be visible in Power BI's Navigation dialog
Parameters:
    subdomain - the name of the customer's subdomain (e.g. https://[subdomain].bamboohr.com/)
*/
shared NavigationTable = (subdomain as text) =>
    let
        objects = #table(
            {"Name","Key","Data","ItemKind", "ItemName","IsLeaf"},
            {
                {"EmployeeDirectory","employeeDirectory",EmployeeDirectory(subdomain), "Table", "Table", true},
                {"Users","users",Users(subdomain), "Table", "Table", true},
                {"Metadata", "metadata",  MetadataTable(subdomain), "Folder", "Folder", false}
            }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        NavTable
;

/*
Purpose:
    Return "metadata" nodes
Parameters:
    subdomain - the name of the customer's subdomain (e.g. https://[subdomain].bamboohr.com/)
*/
MetadataTable = (subdomain as text) as table => 
    let
        objects = #table(
            {"Name","Key","Data","ItemKind", "ItemName","IsLeaf"},
            {
                {"Tables", "tables", Tables(subdomain), "Table", "Table", true},
                {"Fields", "fields", Fields(subdomain), "Table", "Table", true}
        }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        NavTable
;

/*
Purpose:
    Retrieve table of active employees
Parameters:
    subdomain - the name of the customer's subdomain (e.g. https://[subdomain].bamboohr.com/)
Links:
    https://documentation.bamboohr.com/reference#get-employees-directory-1
*/
EmployeeDirectory = (subdomain as text) =>
    let
        Source = GetResource( subdomain, "/employees/directory" ),
        employees = Source[employees],
        #"Converted to Table" = Table.FromList(employees, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "displayName", "firstName", "lastName", "preferredName", "gender", "jobTitle", "workPhone", "mobilePhone", "workEmail", "department", "location", "linkedIn", "workPhoneExtension", "photoUploaded", "photoUrl", "canUploadPhoto"}, {"id", "displayName", "firstName", "lastName", "preferredName", "gender", "jobTitle", "workPhone", "mobilePhone", "workEmail", "department", "location", "linkedIn", "workPhoneExtension", "photoUploaded", "photoUrl", "canUploadPhoto"}),
        #"Changed Type" = Table.TransformColumnTypes(#"Expanded Column1",{{"id", Int64.Type}}),
        #"Inserted Merged Column" = Table.AddColumn(#"Changed Type", "employeeName", each Text.Combine({[lastName], [firstName]}, ", "), type text),
        #"Reordered Columns" = Table.ReorderColumns(#"Inserted Merged Column",{"id", "displayName", "employeeName", "firstName", "lastName", "preferredName", "gender", "jobTitle", "workPhone", "mobilePhone", "workEmail", "department", "location", "linkedIn", "workPhoneExtension", "photoUploaded", "photoUrl", "canUploadPhoto"})
    in
        #"Reordered Columns"
;

/*
Purpose:
    Retrieve table of active employees
Parameters:
    subdomain - the name of the customer's subdomain (e.g. https://[subdomain].bamboohr.com/)
Links:
    https://documentation.bamboohr.com/reference#get-a-list-of-users-1
*/
Users = (subdomain as text) =>
    let
        Source = GetResource( subdomain, "/meta/users" ),
        #"Converted to Table" = Record.ToTable(Source),
        #"Expanded Value" = Table.ExpandRecordColumn(#"Converted to Table", "Value", {"id", "employeeId", "firstName", "lastName", "email", "status", "lastLogin"}, {"id", "employeeId", "firstName", "lastName", "email", "status", "lastLogin"}),
        #"Removed Other Columns" = Table.SelectColumns(#"Expanded Value",{"id", "employeeId", "firstName", "lastName", "email", "status", "lastLogin"}),
        #"Changed Type" = Table.TransformColumnTypes(#"Removed Other Columns",{{"id", Int64.Type}, {"employeeId", Int64.Type}, {"lastLogin", type datetimezone}}),
        #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"lastLogin", "lastLoginUtc"}}),
        #"Added Custom" = Table.AddColumn(#"Renamed Columns", "lastLoginLocal", each DateTimeZone.ToLocal([lastLoginUtc])),
        #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom",{{"lastLoginLocal", type datetimezone}})
    in
        #"Changed Type1"
;

/*
Purpose:
    Retrieve the tables
Parameters:
    subdomain - the name of the customer's subdomain (e.g. https://[subdomain].bamboohr.com/)
Links:
    https://documentation.bamboohr.com/reference#metadata-get-a-list-of-tabular-fields-1
*/
Tables = (subdomain as text) =>
    let
        Source = GetResource( subdomain, "/meta/tables" ),
        #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"alias", "fields"}, {"alias", "fields"}),
        #"Expanded fields" = Table.ExpandListColumn(#"Expanded Column1", "fields"),
        #"Expanded fields1" = Table.ExpandRecordColumn(#"Expanded fields", "fields", {"id", "name", "alias", "type"}, {"id", "name", "alias.1", "type"}),
        #"Renamed Columns" = Table.RenameColumns(#"Expanded fields1",{{"alias", "tableName"}, {"name", "columnDescription"}, {"alias.1", "columnName"}, {"type", "columnDataType"}, {"id", "columnId"}})
    in
        #"Renamed Columns"
;

/*
Purpose:
    Retrieve the fields
Parameters:
    subdomain - the name of the customer's subdomain (e.g. https://[subdomain].bamboohr.com/)
Links:
    https://documentation.bamboohr.com/reference#metadata-get-a-list-of-fields
*/
Fields = (subdomain as text) =>
    let
        Source = GetResource( subdomain, "/meta/fields" ),
        #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "name", "type"}, {"id", "name", "type"}),
        #"Changed Type" = Table.TransformColumnTypes(#"Expanded Column1",{{"id", type number}})
    in
        #"Changed Type"
;

/*
Purpose:
    Retrieve the JSON document from the specified resource
Parameters:
    subdomain - the name of the customer's subdomain (e.g. https://[subdomain].bamboohr.com/)
    resource - the targeted resource (e.g. /employees/directory)
*/
GetResource = (subdomain as text, resource as text) =>
    let
        credential = Extension.CurrentCredential(),
        authorization = "Basic " & Binary.ToText(Text.ToBinary( credential[Key] & ":" & "password" ),0),
        headers = [
             #"Authorization" = authorization,
             #"Content-Type" = "application/json",
             #"Accept" = "application/json"
        ],
        BaseUrl = "https://api.bamboohr.com/api/gateway.php/" & subdomain & "/v1",
        url = BaseUrl & resource,
        source = Web.Contents(url, [ Headers = headers ]),
        json = Json.Document(source)
    in
        json
;

/*
Purpose:
    Create a navigation table 
*/
Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable
;

// Data Source Kind description
BambooHrPQExtension = [
    Authentication = [
        Key = []
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
