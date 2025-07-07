from flask import Flask,request, jsonify
import iris
import json
import os

import vectorutils

from flask_restx import Api, Resource, fields

from werkzeug.utils import secure_filename
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploaded_images')
# フォルダがなければ作成
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

app = Flask(__name__)
api = Api(app, version='1.0', title='試しのアプリケーション', description='ファイルアップロード用API')  # <- タイトルなどを変更

@app.route("/hello")
def hello():
    #グローバルはかける
    #g=iris.gref("^Iijima")
    #g["None"]="あいうえお"
    # language=pythonのメソッドはWSGIから呼べない
    #modori=iris.cls("Try.WSGI").t1()
    # ##class(FishDetector.Utils).t1()
    modori=vectorutils.hello()
    #modori={"Msg":"こんにちは"}
    return jsonify(modori)

@app.route('/upload',methods=['POST'])
def upload():
    import iris
    file = request.files['fish']
    filefullpath=os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(filefullpath)

    #ベクトル検索
    modori=vectorutils.searchVec(filefullpath)
    #カンマ区切りの文字列で返る
    #modori={"FishName":"アジ","FishInfo":"アジの塩焼きがおいしいです"}
    return jsonify(modori)



resource_fields = api.model("Json Bodyです", {
    "FishName": fields.String,
    "FishInfo": fields.String,
})


if __name__ == "__main__":
    app.run(host="0.0.0.0",port=8080,debug=True)