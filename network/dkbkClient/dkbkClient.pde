import processing.net.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;

//テキストフィールドに文字を打ってEnterするとサーバーに送る。
//データを受け取るとlogに表示。

Client client;
int client_id;
HashMap<Integer, ArrayList<Line>>lines=new HashMap<Integer, ArrayList<Line>>();
ArrayList<Integer> disconList = new ArrayList<Integer>(); 

TextField field;
Choice log;

public class Line extends ArrayList<PVector> {
}

public void setTitle() {
  frame.setTitle("dkbkClient ::"+lines.size());
}

void setup() {

  size(250, 200);
  client_id=-1;
  client=new Client(this, "127.0.0.1", 8181);//ローカルとのみ通信

  field=new TextField(10);
  //  field.addActionListener(new MyActionListener());
  field.addActionListener(new ActionListener() {
    public void actionPerformed(ActionEvent e) {
      write("TXT", field.getText());
      field.setText("");
    }
  }
  );
  log=new Choice();
  log.add("Serverから受信したデータ");
  add(field);
  add(log);

  textSize(20);
  textAlign(CENTER);

  setTitle();
}

void mousePressed() {
  write("ADDLINE");
  lines.get(client_id).add(new Line());
}

void mouseDragged() {
  write("POINT", mouseX+","+mouseY+","+0);
  PVector p=new PVector(mouseX, mouseY);
  lines.get(client_id).get(lines.get(client_id).size()-1).add(p);
}

void draw() {
  if (client_id==-1)write("GETID");//IDを持っていないなら要求する
  while (!disconList.isEmpty ()) {
    lines.remove(disconList.remove(0));
  }

  background(255);

  noFill();

  for (Integer ky : lines.keySet ()) {
    ArrayList<Line>usr=lines.get(ky);
    for (int j=0; j<usr.size (); j++) {
      Line line=usr.get(j);
      beginShape();
      for (int i=0; i<line.size (); i++) {
        PVector p=line.get(i);
        vertex(p.x, p.y);
      }
      endShape();
    }
  }

  fill(0);
  text(client_id, width/2, height/2);//自分のIDを大きく表示

  while (client.available ()>0) {
    if (!receiveData(client))break;
  }
}

void write(String order, Object... obj) {
  StringBuffer sb=new StringBuffer();
  sb.append(order);
  sb.append(":"+client_id);
  for (Object o : obj)
    sb.append(":"+o.toString());
  sb.append('\n');

  client.write(sb.toString());
}

boolean receiveData(Client client) {//次のデータを読み込む必要性がある可能性があるときにtrueを返す
  String receive=client.readStringUntil('\n');//クライアントから送られてきた情報
  if (receive==null)return false;//送り途中なら待つ

  receive=receive.replace("\n", "");//改行コードを消しちゃう

  log.insert(receive, 0);
  println(receive+"::on client"+client_id+"  "+frameCount);

  String input[]=receive.split(":");//':'で区切る
  Order order=Order.find(input[0]);
  int id=input.length>1?int(input[1]):-1;

  switch(order) {
  case ID:
    if (client_id == -1) {
      if (!lines.containsKey(id)) {
        lines.put(id, new ArrayList<Line>());
        setTitle();
      }
      client_id=id;
      write(order.OK.toString());
    }
    break;
  case IN:
    for (int i=2; i<input.length; i++) {
      if (!lines.containsKey(input[i])) {
        lines.put(int(input[i]), new ArrayList<Line>());
        setTitle();
      }
    }
    break;
  case OUT:
    setTitle();
    disconList.add(id);
    break;
  case ADDLINE:
    if (id==client_id)break;
    lines.get(id).add(new Line());
    break;
  case POINT:
    if (id==client_id)break;
    String pString[]=input[2].split(",");
    PVector p=new PVector(float(pString[0]), float(pString[1]), float(pString[2]));
    lines.get(id).get(lines.get(id).size()-1).add(p);
    break;
  default:
    break;
  }

  if (client_id==-1)write("GETID");//IDを持っていないのにデータ送信をされているようなら要求する

  return true;
}

void serverEvent(Server server, Client client) {
  println("server Event::on client"+client_id);
}

void clientEvent(Client client) {
  //  println("client Event::on client"+client_id);
  receiveData(client);
}

void disconnectEvent(Client client) {
  println("discon Event::on client"+client_id);
}

