Class Try.MCPREST Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "utf-8";

Parameter CONVERTINPUTSTREAM = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/hello" Method="POST" Call="hello" Cors="true"/>
<Route Url="/load" Method="POST" Call="load" Cors="true"/>
</Routes>
}

/// csvファイルUpload＆保存
/// [ファイル形式]（UTF8で保存）
///  Name,Email,Location
/// 
ClassMethod load() As %Status
{
    /*　仕様
    load-api-serverをという名前のMCPサーバをPythonで作成してください。
    MCPサーバが実行するREST APIのベースURLは、http://localhost:8081/csv です。
    POST要求を受け付ける /load があります。これを loadcsv　の名称でツールとして公開してください。
    /load のPOST要求時、フォームエレメント名 file　でテキストファイルを指定できます。
    MCPサーバの応答フォーマットは、以下の通りです。（Personテーブルの情報が応答として戻ります。）
    [
        {
            "ID": "1",
            "Name": "山田太郎",
            "Email": "yamada@mail.com",
            "Location": "東京都"
        },
        {
            "ID": "2",
            "Name": "鈴木花子",
            "Email": "hana@mail.com",
            "Location": "大阪府"
        }
    ]
    コードはc:\temp\test\loadcsv.pyに保存してください。
    */
    #dim ex As %Exception.AbstractException
    #dim %request As %CSP.Request
    set status=$$$OK
    try {
        set basepath="/data/csvfile/"
        set upstream=$get(%request.MimeData("file", 1))
        set fname=%request.MimeData("file",1).FileName
        set fo=##class(%Stream.FileBinary).%New()
        set csvfullpath=basepath_fname
        do fo.LinkToFile(csvfullpath)
        do fo.CopyFrom(upstream)
        $$$ThrowOnError(fo.%Save())
        // CSVの中身をロード（ヘッダ行は無視、UTF8で読み込む）
        // Sample.Personテーブルががあるかどうか確認
        set check=##class(INFORMATION.SCHEMA.TABLES).%ExistsId("Sample||Person")
        if check=0 {
            //存在してなかったらテーブル作成
            &sql(CREATE TABLE Sample.Person (Name VARCHAR(50),Email VARCHAR(50),Location VARCHAR(10)))
        }
        // LOAD DATA実行
        set sql="LOAD DATA FROM FILE '"_csvfullpath_"' INTO Sample.Person USING {""from"":{""file"":{""charset"":""UTF-8"",""header"":true}}}"
        set stmt=##class(%SQL.Statement).%New()
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute()
        if rset.%SQLCODE<0 {
            throw ##class(%Exception.SQL).CreateFromSQLCODE(rset.%SQLCODE,rset.%Message)
        }
        //現在登録されてるPerson情報全件返す（JSONで返す）
        set sql="select ID,Name,Email,Location from Sample.Person"
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute()
        set array=[]
        while rset.%Next() {
            set json={}
            set json.ID=rset.ID
            set json.Name=rset.Name
            set json.Email=rset.Email
            set json.Location=rset.Location
            do array.%Push(json)
        } 
        do array.%ToJSON()
    }
    catch ex {
        set status=ex.AsStatus()
    }
    return status
}

/// body は以下
/// {"name":"お名前"}
ClassMethod hello() As %Status
{
    #dim ex As %Exception.AbstractException
    #dim %request As %CSP.Request
    set status=$$$OK
    try {
        // bodyの中身取得
        set body={}.%FromJSON(%request.Content)
        set json={}
        set json.AccessTime=$ZDATETIME($HOROLOG,16)
        set json.Greeting="こんにちは、"_body.Name_"さん！"
        do json.%ToJSON()
    }
    catch ex {
        set status=ex.AsStatus()
    }
    return status
}

}
