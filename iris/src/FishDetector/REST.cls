Class FishDetector.REST Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "utf-8";

Parameter CONVERTINPUTSTREAM = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/recipe" Method="POST" Call="recipe" Cors="true"/>
<Route Url="/getrecipe" Method="POST" Call="getrecipe" Cors="true"/>
<Route Url="/upload" Method="POST" Call="upload" Cors="true"/>
<Route Url="/hello" Method="POST" Call="hello" Cors="true"/>
</Routes>
}

ClassMethod upload() As %Status
{
    #dim %request As %CSP.Request
    set basepath="/data/images/"
    set upstream=$get(%request.MimeData("fish", 1))
    set fname=%request.MimeData("fish",1).FileName
    set fo=##class(%Stream.FileBinary).%New()
    do fo.LinkToFile(basepath_fname)
    do fo.CopyFrom(upstream)
    set status=fo.%Save()
    if $$$ISERR(status) {
        // ファイル保存失敗
        return status
    }
    // ここから画像検索
    set result=##class(FishDetector.Utils).searchVec(basepath_fname)
    //　カンマ区切りデータで戻る
    set json={}
    set json.FishName=$piece(result,",",1)
    set json.FislInfo=$piece(result,",",2)
    do json.%ToJSON()
    return $$$OK
}

/// さなかの画像ファイル＋ユーザ入力が渡される場合
ClassMethod recipe() As %Status
{
    #dim %request As %CSP.Request
    set basepath="/data/images/"
    set upstream=$get(%request.MimeData("fish", 1))
    set fname=%request.MimeData("fish",1).FileName
    set fo=##class(%Stream.FileBinary).%New()
    do fo.LinkToFile(basepath_fname)
    do fo.CopyFrom(upstream)
    set status=fo.%Save()
    if $$$ISERR(status) {
        // ファイル保存失敗
        return status
    }
    // ここから画像検索
    //　カンマ区切りデータで戻る
    set result=##class(FishDetector.Utils).searchVec(basepath_fname)
    
    // 質問のキーワードを取り出す
    set key=$get(%request.Data("question",1))
    set ans=##class(FishDetector.Utils).AskOllama($piece(result,",",2),key)
    write ans
    /*
    set retjson={}
    set retjson.Answer=##class(FishDetector.Utils).AskOllama($piece(result,",",2),key)
    do retjson.%ToJSON()
    */
    return $$$OK
}

/// POSTのボディ
/// {
///  "UserInput":"ここにユーザが希望するレシピの内容",
///  "FishName":"魚名",
///  "FishInfo":"魚の画像ファイルから得られた補足情報"
/// }
ClassMethod getrecipe() As %Status
{
    #dim %request As %CSP.Request
    set body={}.%FromJSON(%request.Content)
    // systemプロンプトの作成＝魚名と魚情報
    set systemprompt=body.FishName_"："_body.FishInfo
    set userprompt=body.UserInput
    set ans=##class(FishDetector.Utils).AskOllama(systemprompt,userprompt)
    //set ^iijima=ans
    //write ans
    
    set retjson={}
    set retjson.Answer=ans
    do retjson.%ToJSON()
    return $$$OK
}

ClassMethod hello() As %Status
{
    set ret=##class(FishDetector.Utils).t1("aiueo")
    set json={}
    set json.RetMessage=ret
    do json.%ToJSON()
    return $$$OK
}

}
