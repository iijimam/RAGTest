
def hello():
    msg={"Hello":"あいえうお"}
    return msg

# LINE社のモデルを利用：画像からベクトル取り出す
# リスト戻る
def getImageVec(file):
    import io
    import requests
    from PIL import Image
    import torch
    from transformers import AutoImageProcessor, AutoModel, AutoTokenizer
    import time

    HF_MODEL_PATH = 'line-corporation/clip-japanese-base'
    device = "cuda" if torch.cuda.is_available() else "cpu"
    #tokenizer = AutoTokenizer.from_pretrained(HF_MODEL_PATH, trust_remote_code=True)
    tokenizer = AutoTokenizer.from_pretrained(HF_MODEL_PATH, trust_remote_code=True,legacy=True)
    processor = AutoImageProcessor.from_pretrained(HF_MODEL_PATH, trust_remote_code=True)
    model = AutoModel.from_pretrained(HF_MODEL_PATH, trust_remote_code=True).to(device)

    #image_path = "aji.jpg"  # 任意の画像ファイルを指定
    #image = Image.open(image_path)
    image = Image.open(file)
    #image = processor(image, return_tensors="pt").to(device)

    # 画像のベクトル取得
    def get_single_image_embedding(my_image):
        #start = time.time()  # 現在時刻（処理開始前）を取得
        image = processor(images=my_image , return_tensors="pt")
        embedding = model.get_image_features(**image).float()
        # convert the embeddings to numpy array
        return embedding.cpu().detach().numpy()

    imagevector=get_single_image_embedding(image)[0]
    #print(imagevector)
    return imagevector.tolist()

# 引数に画像を指定
# 画像と一致する名称をベクトルを検索し、補足情報（FishInfo）を入手
# 補足情報はRAGとして使う
def searchVec(file):
    import iris
    import time
    import irisbuiltins
    try:
        start = time.time()  # 現在時刻（処理開始前）を取得
        veclist=getImageVec(file)
        end = time.time()  # 現在時刻（処理完了後）を取得
        time_diff = end - start  # 処理完了後の時刻から処理開始前の時刻を減算する
        #print(f"★★ 画像のベクトル化の時間：{time_diff}")  # 処理にかかった時間データを使用

        #print(vec[0].tolist())
        # TO_VECTOR()に指定するため、リスト→文字列→[] 取り除く
        vecparm=str(veclist)[1:-1]
        #print(vecparm)

        start = time.time()  # 現在時刻（処理開始前）を取得
        #sql="select FishName,VECTOR_COSINE(FishInfoVec, TO_VECTOR(?, DOUBLE, 384)) as cos,fishinfo from FishDetector.Fish ORDER BY cos desc"
        sql="select top 1 FishName,FishInfo,VECTOR_COSINE(FishNameVec, TO_VECTOR(?, DOUBLE, 384)) as cos from FishDetector.Fish ORDER BY cos desc"
        stmt=iris.sql.prepare(sql)
        rset=stmt.execute(vecparm)
        #for row in rset:
        #   print(row)
        row=next(rset)
        modori={"FishName":row[0],"FishInfo":row[1]}
        return modori
    
        #魚の名称と魚の補足情報をカンマ区切りの文字列に
        #fishdata=",".join(row[:-2])

        #end = time.time()  # 現在時刻（処理完了後）を取得
        #time_diff = end - start  # 処理完了後の時刻から処理開始前の時刻を減算する
        ##print(f"★★ ベクトル検索だけの処理時間：{time_diff}")  # 処理にかかった時間データを使用
        #return fishdata
        ##return row

    except irisbuiltins.SQLError as ex:
        raise

# system ：魚情報（RAGとして使用）
# input : ユーザプロンプト（好みを入れる）
def AskOllama(system, input):
    import requests
    import json
    import iris
    import time
    start = time.time()  # 現在時刻（処理開始前）を取得

    systemprompt=f"この魚は、{system} 3つのレシピ候補とそれぞれの作り方を分かりやすく解説してください。"
    #print(f"\n★ システムプロンプト：{systemprompt}")
    #print(f"\n★ ユーザプロンプト：{input}　\n\n***この情報でLLMに質問します***")
    #API_SERVER_URL = "http://ollama:11434/api/chat"
    API_SERVER_URL = "http://54.238.251.191/api/chat"

    def main():
        headers = {"Content-Type": "application/json"}
        data = {
            "model": "pakachan/elyza-llama3-8b",
            "messages": [
                {
                    "role": "system",
                    "content": f"{systemprompt}",
                },
                {
                    "role": "user",
                    "content": f"{input}",
                }
            ],
            "stream": True
        }

        response = requests.post(API_SERVER_URL, headers=headers, json=data)
        response.raise_for_status()
        
        #print(response.text)

        answer_text =""
        for line in response.iter_lines():
            decoded_line = json.loads(line.decode('utf-8'))
            answer_text+=decoded_line['message']['content']

        #print(answer_text)
        return answer_text

    answer=main()

    #end = time.time()  # 現在時刻（処理完了後）を取得
    #time_diff = end - start  # 処理完了後の時刻から処理開始前の時刻を減算する
    #print(f"処理時間：{time_diff}")  # 処理にかかった時間データを使用
    return answer
