import processing.net.*;
import java.awt.*;
import java.io.*;
//クライアントの接続があった時IDを告知する
//データを受け取るとlogに表示

Server server;
int client_cnt;
HashMap<Integer, Data>usr=new HashMap<Integer, Data>();
HashMap<Client, Integer>clients=new HashMap<Client, Integer>();
ArrayList<Client> disconList = new ArrayList<Client>(); 

Choice list, log;

public class Data extends ArrayList<Line> {
	PImage img;
	float depth[];

	void setImage(int w, int h, int[] pxsl, float[] dep) {
		img=createImage(w, h, RGB);
		img.loadPixels();
		img.pixels=pxsl;
		img.updatePixels();
		depth=dep;
	}
}
public class Line extends ArrayList<PVector> {
}

public void setTitle() {
	frame.setTitle("dkbkServer ::"+usr.size());
}

void setup() {
	size(300, 200);
	server=new Server(this, 8181);
	client_cnt=1;//0はサーバー,1以降がクライアントとする

	list=new Choice();
	log=new Choice();
	list.add("現在接続中のClient");
	log.add("Clientから受信したデータ");
	add(list);
	add(log);

	setTitle();

	imageMode(CENTER);
}

void draw() {
	while (!disconList.isEmpty ())
		disconnectClient(disconList.remove(0));

	background(255);
	noFill();

	for (Integer id : usr.keySet ()) {
		Data data=usr.get(id);
		if (data.img!=null) {
			tint(100, 255);
			image(data.img, width/2, height/2, width, height);
			noTint();
		}
		for (Line line : data) {
			beginShape();
			for (int i=0; i<line.size (); i++) {
				PVector p=line.get(i);
				vertex(p.x, p.y);
			}
			endShape();
		}
	}

	while (server.available ()!=null) {//クライアントからデータが送られてきているか
		Client client=server.available();
		if (!receiveData(client))break;
	}
}

boolean receiveData(Client client) {//次のデータを読み込む必要性がある可能性があるときにtrueを返す
	String receive=client.readStringUntil('\n');//クライアントから送られてきた情報
	if (receive==null)return false;//送り途中なら待つ
	receive=receive.replace("\n", "");//改行コードを消しちゃう

	log.insert(receive, 0);
	//println(receive+"::on server");

	String input[]=receive.split(":");//':'で区切る
	Order order=Order.find(input[0]);
	int id=input.length>1?int(input[1]):-1;
	if (input.length>1&&int(input[1])==-1)//IDが登録されていないクライアントからの送信の時
		appearClient(client);

	switch(order) {
		case GETID://ID要求
		appearClient(client);
		break;
		case DATA://OKの派生。さらにClientが持っていたデータを受け取る
		int[] wh=int(input[2].split(","));
		usr.get(id).setImage(wh[0], wh[1], int(input[3].split(",")), float(input[4].split(",")));
		case OK://IDを受け取ったことが確認できた
		sendAllClientData(client);
		break;
		case ADDLINE:
		if (id==-1) {
			println("NO ID USER");
			break;
		}
		usr.get(id).add(new Line());
		writeExcept(client, receive);
		break;
		case POINT:
		if (id==-1) {
			println("NO ID USER");
			break;
		}
		String pString[]=input[2].split(",");
		PVector p=new PVector(float(pString[0]), float(pString[1]), float(pString[2]));
		usr.get(id).get(usr.get(id).size()-1).add(p);
		writeExcept(client, receive);
		break;
		case UNDO:
		if (id==-1) {
			println("NO ID USER");
			break;
		}
		if (usr.get(id).size()>0)
			usr.get(id).remove(usr.get(id).size()-1);
		writeExcept(client, receive);
		break;
		case DELETE:
		writeExcept(client, receive);
		break;
		case TXT:
		writeExcept(client, receive);
		break;
		case ADDIMAGE:
		if (id==-1) {
			println("NO ID USER");
			break;
		}
		usr.get(id).add(new Line());
		writeExcept(client, receive);
		break;
	}

	return true;
}

//Client の接続があった時に自動的に呼ばれる
void serverEvent(Server server, Client client) {
	println("server Event::on server");

	appearClient(client);
}

//あるクライアントのみに文字列データを送信する
void write(Client client, String order, int id, Object... obj) {
	StringBuffer sb=new StringBuffer();
	sb.append(order);
	sb.append(":"+id);
	for (Object o : obj)
		sb.append(":"+o.toString());
	sb.append('\n');

	client.write(sb.toString());
}

//全てのクライアントにオーダーを指定してデータを送信する
void write(String order, int id, Object... obj) {
	StringBuffer sb=new StringBuffer();
	sb.append(order);
	sb.append(":"+id);
	for (Object o : obj) {
		sb.append(":"+o.toString());
	}
	sb.append('\n');

	server.write(sb.toString());
}

//あるクライアントのみに文字列データを送信する
void write(Client client, String send) {
	client.write(send+'\n');
}

//全てのクライアントに文字列データを送信する
void write(String send) {
	server.write(send+'\n');
}

//接続されている特定のクライアント以外のすべてのクライアントにオーダーを指定してデータを送信する
//あるクライアントから他のクライアントにデータを送信するときに使う。
void writeExcept(Client client, String order, int id, Object... obj) {
	for (Client c : clients.keySet ()) {
		if (!client.equals(c))
			write(c, order, id, obj);
	}
}

//接続されている特定のクライアント以外のすべてのクライアントに文字を送信する
void writeExcept(Client client, String send) {
	for (Client c : clients.keySet ()) {
		if (!client.equals(c))
			write(c, send);
	}
}

//接続されている全てのクライアントにログインユーザーのデータを送信する
void sendAllClientData(Client client) {
	write(client, Order.IN.toString(), 0, usr.keySet().toArray());
	for (Integer id : usr.keySet ()) {
		ArrayList<Line>data=usr.get(id);
		StringBuffer sb=new StringBuffer();
		for (Line line : data) {
			write(client, Order.ADDLINE.toString(), id);
			for (PVector p : line)
				write(client, Order.POINT.toString(), id, p.x+","+p.y+","+p.z);
		}
	}
}

void appearClient(Client client) {//新しいクライアントが出現
	if (client==null)println("client NULL");

	if (!clients.containsKey(client)) {
		println("UnKnown");
		write(client, Order.ID.toString(), client_cnt);//IDを教える
		writeExcept(client, Order.IN.toString(), 0, client_cnt);//他者に新しい人が入ったことを教える
		usr.put(client_cnt, new Data());
		clients.put(client, client_cnt);
		list.add(str(client_cnt));
		setTitle();
		client_cnt++;
	} else {
		println("Know");
		write(client, Order.ID.toString(), clients.get(client));//既知のクライアントなら登録済みのIDを教える
	}
}

void clientEvent(Client client) {
	println("client Event::on server");
}

//Client 切断があった時に自動で呼ばれる部分。
//ここでdisconnectClient の処理をやるとdrawの方に書いたfor文でエラーが発生するのでだめ。
void disconnectEvent(Client client) {
	disconList.add(client);
}

//切断があった時に実際にクライアントを削除する部分
void disconnectClient(Client client) {
	print("discon Event::on server\n");
	if (clients.containsKey(client)) {
		write(Order.OUT.toString(), clients.get(client));
		usr.remove(clients.get(client));
		list.remove(str(clients.get(client)));
		clients.remove(client);
		setTitle();
	}
}

