# RAG＋生成AI　IRIS側コード

試しのコード置き場

## IRIS

Claudeに設定するMCPサーバから呼び出すためにはhttps通信が必須のため、https化しています。（自己証明使用）

LLMのサーバは固定IPではないので、以下毎度変更必要
[FishDetector.Util.cls](/iris/src/FishDetector/Utils.cls?L140)

### コンテナビルド時で作成している内容

```
docker compose up -d
```
で、ビルド時に以下作成

- 日本語ロケール変更

- SuperUserなどのパスワード無期限設定（SYS）

- Embedded Python用設定

- RESTアプリ用パス（/fish2）作成

- 必要なコードインポート

    [FishDetector](/iris/src/FishDetector/) 以下コードをインポート

- RAG用テーブル作成

    [FishDetector.Fish](/iris/src/FishDetector/Fish.cls) に [fish_text_vectors.jsonl](./iris/fish_text_vectors.jsonl) をロードしてる


### テスト実行用メソッド

コンテナログイン＆IRISログイン
```
docker exec -it irisragtest bash
iris session iriis
```

- 画像のベクトル入手
```
set l=##class(FishDetector.Utils).getImageVec("/data/aji.jpg")
zwrite l
```

- 画像ファイルを引数に与え、魚名と参考情報を返す

```
set l=##class(FishDetector.Utils).searchVec("/data/tai.jpg")
zwrite l
```

### テスト用REST

- Uploadテスト（POST要求）
　
    アップロード時、[/data/images/ここ](/iris/data/images/) にファイルを配置します。imagesのアクセス権をホスト上で設定しておかないと配置できないので必要だれば、chmodしてください。

    URL配下の通り。

    ```
    https://localhost:8443/fish2/upload
    ```

    Headerには以下設定
    ```
    Content-Type: multipart/form-data
    ```
    Bodyには、fish で画像ファイルを設定

    以下のような結果が返る予定
    ```
    {
        "FishName": "タイ",
        "FislInfo": "タイ（Sea Bream）は、Pagrus majorという学名を持つ魚です。紅色で高級感がある。お祝いの席で使われる。特徴があり、旬は春です。調理法としては塩焼き、刺身、鯛めしがあり、味は上品で淡白な旨み。相性の良い食材は昆布、塩、米です。郷土料理には鯛めし（愛媛、香川）があり、小型：焼き物、大型：刺身や鯛めしなどの調理法がサイズによって使い分けられます。"
    }
    ```

- レシピ生成テスト（POST要求）

    ```
    https://localhost:8443/fish2/getrecipe
    ```
    BODYに以下のようなJSONを指定（プロパティ名大小文字区別します）

    ```
    {
        "UserInput":"夏バテ防止で３０分ぐらいでできるレシピを知りたい",
        "FishName": "アジ",
        "FislInfo": "旬は夏です。調理法としては刺身、南蛮漬け、フライ、なめろうがあり、味は淡白でうま味が強く、脂が乗ると非常に美味。相性の良い食材は玉ねぎ、酢、味噌、生姜です。郷土料理にはアジのなめろう（千葉）、南蛮漬け（九州）があり、小型：唐揚げ、中型：刺身や干物などの調理法がサイズによって使い分けられます。"
    }
    ```

    以下のような結果が返る予定
    ```
    {
        "Answer": "暑い夏にピッタリなアジを使ったレシピを3つご提案します。どれも30分以内で完成する簡単で美味しいメニューです。\n\n**レシピ1: アジの塩焼き&レモン**\n作り方:\n1. アジを3枚におろす。\n2. 塩を両面にふる。\n3. レモンを切っておく。\n4. フライパンに油を熱し、アジを皮目を下にして焼く。5分程したら裏返して、さらに5分焼く。\n5. 完成したらレモンを絞り、好みでポン酢や山葵を添える。\n\n**レシピ2: アジのマリネサラダ**\n作り方:\n1. アジを3枚におろす。\n2. ボウルにアジ、セロリ、きゅうり、ミニトマトを入れる。\n3. マヨネーズと酢を混ぜたドレッシングで和える。\n4. 塩胡椒して、刻みパセリを散らす。\n\n**レシピ3: アジのユッケ風**\n作り方:\n1. アジを3枚におろす。\n2. ボウルにアジ、玉ねぎ、長ネギ、ゴマ油、しょうゆ、みりん、酢を入れる。\n3. 和える。好みで生姜やニンニクを加える。\n\nこれらのレシピは夏バテ防止に役立つ栄養素が含まれています。アジにはビタミンB12やDHAが、セロリやきゅうりにはカリウムや水分が、玉ねぎや長ネギには硫化アリルや食物繊維が含まれます。これらの成分は夏バテの予防や解消に効果的です。"
    }
    ```


## Jupyter用仮想環境作成

Embeddingのテストに使用。

2025/6/23 LINEのCLIPでエラーが出てしまって動かない問題発生

以下、チャットGPTの回答

fishTextToVector-BCK.ipynb は、LINEのCLIPを使っているが、新しい環境でPIPし直すと以下エラーが出て動かなかった

LINEのモデルが Hugging Face Hub から rinna/clip-vit-b-patch16 という別モデルを内部で参照していることがわかりました。

✅ 今回のエラーの原因

line-corporation/clip-japanese-base の中で RinnaCLIPModel を使っており、内部で以下のようなことをしている：

pythonコピーする編集するRinnaCLIPConfig.from_pretrained(config.model_name)
しかし、その config.model_name に指定されている rinna/clip-vit-b-patch16 の構成が自動では読み込めず、vision_config などが None になってしまっています。
 
❗ 結論（2025年6月時点）

LINEの clip-japanese-base は以下の理由で Hugging Face Transformers だけでは安定して動かせません：
- モデル内部が rinna/clip に依存しており、それを中で from_pretrained() で呼び出している
- そのときの config に vision_config や text_config を 外部から与える手段がない
- AutoModel や trust_remote_code=True を使っても、完全な再帰的初期化には対応していない

ということで、堀田さんコードを使用。

> 現時時点で文字に対応する画像がなかなかヒットしない。tai.jpgぐらい


### 仮想環境作成
```
python3 -m venv notebook
```

### アクティベート
```
source ./notebook/bin/activate
```