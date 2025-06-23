Class FishDetector.Fish Extends %Persistent
{

Property FishName As %String;

Property FishInfo As %String(MAXLEN = 10000);

Property FishNameVec As %Vector(DATATYPE = "DOUBLE", LEN = 384);

Index FishInfoIdx On FishInfo;

Index FishNameIdx On FishName;

/// Listがやってくる
ClassMethod loaddata(file) [ Language = python, SqlProc ]
{
    import iris
    import irisbuiltins
    import json
    import time
    start = time.time()  # 現在時刻（処理開始前）を取得
    try:
        with open(file, "r", encoding="utf-8") as f:
            fish_docs = [json.loads(line) for line in f]
        
        sql="insert into FishDetector.Fish (FishName,FishInfo,FishNameVec) Values(?,?,TO_VECTOR(?,DOUBLE,384))"
        stmt=iris.sql.prepare(sql)
        for item in fish_docs:
            #print(type(item["embedding"][0]))
            embeddingstr=str(item["embedding"][0])
            print(embeddingstr[1:-1])
            rs=stmt.execute(item["fishname"],item["text"],embeddingstr[1:-1])            
            #rs=stmt.execute(item["fishname"],item["text"],item["embedding"][0])
    
    except irisbuiltins.SQLError as ex:
        print(str(repr(ex)))
        print(ex.sqlcode)
        print(ex.message)
        print(ex.statement)
        raise
    
    end = time.time()  # 現在時刻（処理完了後）を取得
    time_diff = end - start  # 処理完了後の時刻から処理開始前の時刻を減算する
    print(f"処理時間：{time_diff}")  # 処理にかかった時間データを使用
}


/// 未使用
ClassMethod search(file As %String) [ Language = python ]
{
from PIL import Image
from transformers import CLIPProcessor, CLIPModel
import iris
import time

start = time.time()  # 現在時刻（処理開始前）を取得
# モデルとプロセッサの準備
model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
# 1. CLIPモデルのロード
model_name = "openai/clip-vit-base-patch16"
model = CLIPModel.from_pretrained(model_name)
processor = CLIPProcessor.from_pretrained(model_name)

# 2. 画像のロード
#image_path = file  # 任意の画像ファイルを指定
image = Image.open(file)

# 画像のベクトル取得
def get_single_image_embedding(my_image):
    start = time.time()  # 現在時刻（処理開始前）を取得
    image = processor(images=my_image , return_tensors="pt")
    embedding = model.get_image_features(**image).float()
    # convert the embeddings to numpy array
    retval = embedding.cpu().detach().numpy()

    end = time.time()  # 現在時刻（処理完了後）を取得
    time_diff = end - start  # 処理完了後の時刻から処理開始前の時刻を減算する
    print(f"★★画像ベクトル化　処理時間：{time_diff}")  # 処理にかかった時間データを使用
    return retval

end = time.time()  # 現在時刻（処理完了後）を取得
time_diff = end - start  # 処理完了後の時刻から処理開始前の時刻を減算する
print(f"★★CLIPモデルの準備＋画像ロードまでの処理：{time_diff}")  # 処理にかかった時間データを使用

try:
    vec=get_single_image_embedding(image)
    veclist=str(vec[0].tolist())
    #print(vec[0].tolist())
    print(veclist[1:-1])

    start = time.time()  # 現在時刻（処理開始前）を取得
    sql="select VECTOR_COSINE(FishInfoVec, TO_VECTOR(?, DOUBLE, 384)) as cos,fishinfo from FishDetector.Fish ORDER BY cos desc"
    stmt=iris.sql.prepare(sql)
    rset=stmt.execute(veclist[1:-1])
    for row in rset:
        print(row)
    end = time.time()  # 現在時刻（処理完了後）を取得
    time_diff = end - start  # 処理完了後の時刻から処理開始前の時刻を減算する
    print(f"★★ベクトル検索だけの処理時間：{time_diff}")  # 処理にかかった時間データを使用
except irisbuiltins.SQLError as ex:
    raise
}

Storage Default
{
<Data name="FishDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>FishName</Value>
</Value>
<Value name="3">
<Value>FishInfo</Value>
</Value>
<Value name="4">
<Value>FishNameVec</Value>
</Value>
</Data>
<DataLocation>^FishDetector.FishD</DataLocation>
<DefaultData>FishDefaultData</DefaultData>
<IdLocation>^FishDetector.FishD</IdLocation>
<IndexLocation>^FishDetector.FishI</IndexLocation>
<StreamLocation>^FishDetector.FishS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
