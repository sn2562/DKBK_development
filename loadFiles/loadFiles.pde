//processing-java --run --force --sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/loadFiles --output=sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/loadFiles --force

FileList p;

void setup(){
	size(500,500);
	p = new FileList();
	println("p "+p.getFileList().length);
	console(p.getFileList());

	noLoop();
}
void draw(){
}

void console(String[] fileArray){
	if (fileArray != null) {
		for(int i = 0; i < fileArray.length; i++) {
			String[] m = match(fileArray[i], ".dsd");	//画像を取り出す
			if(m != null){//検索結果あり
				println(fileArray[i]);

			}else{//不一致

			}
			//			
			//			if (fileArray[i].endsWith(".dsd")) {// 後方一致（接尾辞）です
			//				System.out.println("スケッチデータです "+fileArray[i]);
			//			}else if (fileArray[i].endsWith(".png")) {
			//				System.out.println("画像です "+fileArray[i]);
			//				//TODO : 画像を読み込む
			//				Image img;
			//				//					String path = filePath+"/"+fileArray[i];
			//				//					img = getImage(getCodeBase(), path);
			//
			//				//TODO : サムネイルを表示する
			//
			//			}else{
			//				System.out.println(fileArray[i]);
			//
			//			}
		}
	} else{
		//		System.out.println(directory1.toString() + "　は存在しません" );
	}
}