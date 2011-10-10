/*
 __Software: Este software contem vários modos de operação:
     1) ModoWeb habilita um micro servidor web, sendo possivel interagir com o pino digital que controla um rele, escreve no LCD.
     2) ModoLuz interage com o sensor de movimento, e ativa o rele da lampada.
     3) modoInvasor interage com o sensor de movimento e manda um e-mail.
     4) ModoSobre apenas informa versões e creditos.
     5) Modo Despertador, lê o chip RTC que informa a hora e acende a luz em determinado horário.
     6) Para interagir com esses modulos é usado Receptor Infrared de TV e um controle remoto.
	 IDE usada do Arduino v022.
 __Hardware: LCD 16x2, Ethernet Shield, rele, transistor npn, sensor de movimento, Receptor Infrared (capacitor), Controle Remoto. 
     Ligação LCD: LCD para o HCF4094
     Relê: (Positivo > fonte externa 12v),(Gnd > Transistor NPN).
     Transistor NPN: Coletor: GND Rele, Base: Resistor 70 ohms Pino Arduino(pinDigRele), Emissor: GND Arduino e GND Fonte 12v.
     Sensor Movimento: Alimentação 12v fonte externa, Pino Arduino PullUp internto ativado(pinDigMov), Gnd Arduino.
     Receptor InfraRed TV: Capacitor 4.7 uf, Gnd, 5v, Pino Arduino(pinDigIC) > Resistor 100ohms; *necessario desconexão para programar pois usa o mesmo pino da serial.
	 DS1302: CE > 5 Arduino, IO > 6 Arduino, CLK > 6 Arduino
 __Autor: Rafael Gimenes Leite falecom@rafaelgimenes.net -07/09/2011 v0.
 __Licenca: Este software pode ser livremente estudado e alterado mas gostaria de ser avisado :).
 */
// fazendo includes necessários
#include <Ethernet.h>
#include <SPI.h>
#include <LCD3Wire.h>
#include <IRremote.h>
#include <stdio.h>   //DS1302
#include <string.h>  //DS1302
#include <DS1302.h>  //DS1302
//teclas controle
#define t1 0x966
#define t2 0x7D1
#define t3 0xD1
#define t4 0x8D1
#define t5 0x4D1
#define t6 0x9D1
#define t7 0x1D1
#define t8 0x896
#define t9 0x96
#define t10 0x481
#define t11 0xC81
#define lcdLinhas 2  
//pinos Digitais
#define pinDigLcdDout 3  //Dout pin
#define pinDigLcdStr 4  //Strobe pin
#define pinDigLcdClk 2  //Clock pin
#define pinDigRele 8 //pino de acionamento do rele
#define pinDigMov 9 //pino de entrada do sinal do sensor de movimento
#define pinDigIC 0 //pino receptor Infrared *é o mesmo do Receptor Serial, temos que desconectar pra programar o microcontrolador.
#define pinDigDsCE 5  //DS1302 CE
#define pinDigDsIO 6  //DS1302 IO
#define pinDigDsSCLK 7 //DS1302 CLK

// declarando mac, ip, gateway
byte mac[] = {0xDE,0xAD,0xBE,0xEF,0xFE,0xED};
byte ip[] = {10,0,0,20}; 
byte gt[] = {10,0,0,1};
byte snet[] = {255,255,255,0};
byte eip[] = {187,45,214,134}; //ip servidor rafaelgimenes.net para acessar os php que manda e-mail.
// variáves de controle
int cntMovL=0; //contador sensor de movimento sinal LOW
int cntMovH=0; //contador sensor de movimento sinal HIGH
unsigned long ultimoEmail=0; //milisegundos do envio de email
int modo=0; //variação que seta a ação do sistema
int maxLinha=80; //para controle modo server
String linhaEntrada=String(maxLinha); //para controle modo server
char txtWebLcd1[16]; //variavel Linha1 valor recebido do form pro display
char txtWebLcd2[16]; //variavel Linha2 valor recebido do form pro display
boolean releAtivado=false; //para controle modo server 
int cntChar=0; //para controle modo webserver
char impdta[50]; //DS1302 para impressao da data
int dta[7] = {2010,7,7,9,00,2,4};//DS1302 0=ano,1=mes,2=dia,3=hora,4=minuto,5=segundo,6=dia da semana;
int almH=5; //horário do alarme
int almM=37; // minuto do alarme
DS1302 rtc(pinDigDsCE,pinDigDsIO,pinDigDsSCLK); // objeto DS1302
IRrecv cRecpIR(pinDigIC); //objeto do Receptor IR
decode_results resCtrl; //objeto Resultados receptor IR
LCD3Wire lcd = LCD3Wire(lcdLinhas, pinDigLcdDout,pinDigLcdStr, pinDigLcdClk); //objeto do lcd
Server servidor(9703); //cria objeto servidor porta 9703
Time t;
/*
* Setup, inicia alguns objetos.
*/
void setup()
{
	cRecpIR.enableIRIn(); //habilita receptor IR
	lcd.init(); //inicia o lcd 
	iniciaRede();
	servidor.begin();
	pinMode(pinDigRele,OUTPUT); //setando o sinal como saida pino do rele
	pinMode(pinDigMov,INPUT); //setando sinal como entrada pino do sensor movimento
	digitalWrite(pinDigMov,HIGH); //setando *pull-up evitando ocilação sinal;sensor ligado no GND e no pinDigMov internamente do Atmega
	delay(500); //espera 5 segundos pra ir pro loop
	modoSobre(); 
}
/*
* Loop Principal.
*/
void loop()
{    
	t = rtc.time(); //pegando sempre a hora
	modoServidor(0); //já ativa direto o modo web mas no "modo serviço" com o parametro zero.
	modoDespetador(0); //já ativa o modo despertador só que no "modos serviço" com o parametro zero.
	// só ativa o modo invador se for de segunda a sexta entre 7hr e 18hrs e 19 e 23
	if(modo!=3){
		if(t.day>=2 && t.day<=6){
			if ((t.hr > 5 && t.hr < 18)) {  
				modoInvasor(0);
			}
		}      
	}
	//lemos o sensor IR 
	if (cRecpIR.decode(&resCtrl)){
		switch (resCtrl.value){
		case t10: //acende a luz.
			if (!releAtivado){
				digitalWrite(pinDigRele,HIGH);
				releAtivado=true;
				lcd.cursorTo(2,0);
				lcd.printIn("Acendeu a Luz    ");
			}  
			break;
		case t11: //apaga a luz
			if (releAtivado){
				digitalWrite(pinDigRele,LOW);
				releAtivado=false;
				lcd.cursorTo(2,0);
				lcd.printIn("Apagou a Luz     ");
			}   
			break;
		case t1:      modo=1;     break;
		case t2:      modo=2;     break;
		case t3:      modo=3;     break;
		case t4:      modo=4;     break;
		case t5:      modo=5;     break;
		case t6:      modo=6;     break;
		case t7:      modo=7;     break;  
		case t8:      modo=8;     break; 
		case t9:      modo=9;     break;          
		}//fim switch
		cRecpIR.resume(); //libera para ler novamente.
	}//fim if sensor IR 

	//chamamos os modos
	if(modo==1){       modoServidor(1);  }
	else if(modo==2){  modoInvasor(1);   }
	else if(modo==3){  modoLuz();       }
	else if(modo==4){  modoDespetador(1);}
	else if(modo==5){  modoSobre();     }
	
	delay(50);   
}
/*
* Modo Sobre, apenas exibe no lcd a versão do projeto e créditos
*/
void modoSobre(){
	delay(50);
	lcd.clear();
	lcd.printIn("QuartoControl v0");
	lcd.cursorTo(2,0);
	lcd.printIn("by RafaelGimenes");
	delay(150);
	//enviaEmail(2);
}
/*
* Modo Invasor, lê o sensor de movimento se detectado movimento emite um e-mail avisando a presença de alguém no quarto.
*/
void modoInvasor(int exibe){ 
	if (exibe==1){
		lcd.clear();
		lcd.printIn("Modo Invasor");
	}
	int stMov= digitalRead(pinDigMov);//lendo sensor de movimento
	if (stMov==LOW){
		cntMovL++;
		cntMovH=0;
		if (exibe==1){
			lcd.cursorTo(2,0);
			lcd.printIn("SemMovimento");
			lcd.cursorTo(2,13);
			lcd.print(cntMovL);
		}
	}
	if(stMov==HIGH){
		cntMovH++;
		cntMovL=0;
		if (exibe==1){
			lcd.cursorTo(2,0);
			lcd.printIn("MoviDetectado");
			lcd.cursorTo(2,13);
			lcd.print(cntMovH);
		}    
	}
	if (cntMovH > 0){
		if (exibe=1){
			lcd.cursorTo(2,0);
			lcd.printIn("Avisa por Email");
		}  
		//só libera o envio de emails depois de 2 segundos
		if (millis() - ultimoEmail > 20000){
			enviaEmail(1);
		}else{
			if (exibe==1){
				lcd.cursorTo(2,0);
				lcd.printIn("Email Block Tempo");
			}  
		}
		cntMovL=0;
	}
	delay(10);
}
/*
* Modo Despertador, imprime a  hora e se acende a luz se estiver no horário programado.
*/
void modoDespetador(int exibe){
	if (exibe==1){
		lcd.clear();
		lcd.printIn("Modo Despertador");  
		lcd.cursorTo(2,0);
		impHora();
		delay(500);
	}
	
	if(t.day>=2 && t.day<=6){
		if((t.hr==almH)&&(t.min==almM)){
			if(!releAtivado){      
				digitalWrite(pinDigRele,HIGH);
				releAtivado=true;
				lcd.cursorTo(2,0);
				lcd.printIn("Acorda");
			}
		}else if((t.hr==almH)&&(t.min==almM+5)){
				digitalWrite(pinDigRele,LOW);
				releAtivado=false;
		}
	}  
}	
/*
* Modo Luz, lê sensor de movimento, se movimento detectado acende a luz.
*/
void modoLuz(){
	lcd.clear();
	lcd.printIn("Modo Luz");  
	int stMov= digitalRead(pinDigMov); //lê o pino do sendor de movimento
	if (stMov==LOW){
		cntMovL++;
		cntMovH=0;
		lcd.cursorTo(2,0);
		lcd.printIn("SemMovimento");
		lcd.cursorTo(2,13); //debug..
		lcd.print(cntMovL);
	}
	if(stMov==HIGH) {
		cntMovH++;
		cntMovL=0;
		lcd.cursorTo(2,0);
		lcd.printIn("MoviDetecado");
		lcd.cursorTo(2,13); //debug..
		lcd.print(cntMovH);
	}
	//20 segundos 500 mili retornaPotenciomentro e 500 daqui
	if (releAtivado){
		if (cntMovL > 20){
			lcd.cursorTo(2,0);
			lcd.printIn("20s Apagando Luz");
			digitalWrite(pinDigRele,LOW);
			releAtivado = false;
		}
	}
	if(!releAtivado){
		if(cntMovH > 0){
			cntMovL=0;
			digitalWrite(pinDigRele,HIGH);
			lcd.cursorTo(2,0);
			lcd.printIn("Acenda Luz");
			releAtivado=true;
		}
	}
}
/*
* Metodo que envia um e-mail, dependendo do paramêtro muda o assunto.
*/
void enviaEmail(int a) {
	iniciaRede();
	ultimoEmail= millis();
	lcd.clear();
	lcd.printIn("tentando enviar");
	lcd.cursorTo(2,0);
	lcd.printIn("email...");
	// cliente email
	Client clientEmail(eip, 80);
	//conectando no ip
	if (clientEmail.connect()){ 
		lcd.clear();
		lcd.printIn("conectado");
		if (a==0) //Assunto Lampada Desligada
		clientEmail.println("GET /~rafael/r/amail.php?E=1&A=Lampada_Desligada HTTP/1.0");
		else if (a==1) //Assunto Entraram no seu Quarto 
		clientEmail.println("GET /~rafael/r/amail.php?E=1&A=Entraram_No_Seu_Quarto HTTP/1.0");
		else if (a==2) // Assunto Modo Sobre (testes)
		clientEmail.println("GET /~rafael/r/amail.php?E=1&A=ModoSobre HTTP/1.0");
		clientEmail.println(); //se tirar isso não processa o request
		lcd.clear();
		lcd.printIn("enviado");		
		//VerificaRetorno
		if (clientEmail.available()) {
			lcd.clear();
			lcd.printIn("Resposta Email");
			for(int i=0; i < 16; i++){
				char c = clientEmail.read();
				lcd.cursorTo(2,i);
				lcd.print(c);
				delay(200);
			}
			delay(10000);   
		}	  
		if (!clientEmail.connected()){
			lcd.clear();
			lcd.printIn("Cesconectado do email");
			lcd.cursorTo(2,0);
			lcd.printIn("by RafaelGimenes");
			clientEmail.stop();
		}	
	}else {
		lcd.clear();
		lcd.printIn("email fail");
		lcd.cursorTo(2,0);
		lcd.printIn("nao conectou");
	}
}
/*
* Modo Servidor, transforma o arduino em um mini servidor web, permitindo receber paramêtros.
*/
void modoServidor (int exibe){
	//exemplo retirado do "blog do Je" e adaptado pra minha aplicação
	//http://blogdoje.com.br/2010/04/11/teste-do-shield-ethernet-seeeduino/
	Client requisicaoHttp = servidor.available();
	if(exibe==1){
		lcd.clear();
		lcd.printIn("Modo WebService");
	}
	if (requisicaoHttp){
		// uma requisição http em branco.
		boolean linhaAtualvazia = true;
		cntChar=0;
		linhaEntrada="";
		while (requisicaoHttp.connected()){
			if (requisicaoHttp.available()){
				//recebe um caracter enviado pelo browser
				char c = requisicaoHttp.read();
				//se a linha não chegou ao máximo do armazenamento 
				//então adiciona a linha de entrada
				if(linhaEntrada.length() < maxLinha) {
					linhaEntrada+=c; 
				}  
				//Se foi recebido um caracter linefeed - LF e a linha está em branco, a requisição http encerrou.
				if (c == '\n' && linhaAtualvazia){
					if(exibe==1){
						lcd.cursorTo(2,0);
						lcd.printIn("CriandoHTML...");
					}  
					//envia uma resposta padrão ao header http recebido
					requisicaoHttp.println("HTTP/1.1 200 OK");
					requisicaoHttp.println("Content-Type: text/html");
					requisicaoHttp.println();
					//começa a enviar o formulário html
					requisicaoHttp.print("<html>") ;
					requisicaoHttp.print("<body bgcolor='000000'><font face='verdana' color='gray' size='3'>");                
					requisicaoHttp.println("<h3>Quarto do Rafael Gimenes v0</h3>");
					requisicaoHttp.println("Controle da Lampada");
					requisicaoHttp.println("<b>Status:</b> ") ;         
					if(releAtivado) {
						requisicaoHttp.print("LIGADA") ;
					}else if(!releAtivado) {
						requisicaoHttp.print("DESLIGADA") ;
					}
					requisicaoHttp.println("<br><a href='R1=ON'>Ligar</a> | <a href='R1=OF'>Desligar</a><br> ");
					requisicaoHttp.println("Escrever Mensagem no LCD<br>") ;       
					requisicaoHttp.println("<form method='get'><input type=text name='TL' maxlength='32'><input type=submit value=LCD></form><hr>");
					requisicaoHttp.println("by falecom@rafaelgimenes.net - www.rafaelgimenes.net");
					requisicaoHttp.println("</font></body>") ;
					requisicaoHttp.println("</html>");
					break;
				}      
				if (c == '\n') {
					//se o caracter recebido é um linefeed então estamos começando a receber uma 
					//Analise aqui o conteudo enviado pelo submit
					if(linhaEntrada.indexOf("GET")>=0){
						//msg no lcd
						if(linhaEntrada.indexOf("TL=")>=0){ 
							int iniTxt = linhaEntrada.indexOf("TL=") + 3;
							int fimTxt=linhaEntrada.indexOf("HTTP");
							String zerar = "          "; //16 espaços em branco para zerar a array de linhas Chars
							for (int i=0; i < 16;i++){
								txtWebLcd1[i]=zerar.charAt(i);  
								txtWebLcd2[i]=zerar.charAt(i);  
							}
							//primeiralinha
							int j=0;
							for (int i=iniTxt; i < iniTxt+16;i++){     
								txtWebLcd1[j]=linhaEntrada.charAt(i);  
								j++; 
							}
							j=0;
							//segunda Linha
							for (int i=iniTxt+16; i < fimTxt;i++){
								txtWebLcd2[j]=linhaEntrada.charAt(i);      
								j++;
							}
							lcd.clear();
							lcd.printIn(txtWebLcd1);
							lcd.cursorTo(2,0);
							lcd.printIn(txtWebLcd2);
							delay(5000);//5 segundos preso
						}
						// se a linha recebida contem GET e R1=ON etnão ativa o pino do rele
						if(linhaEntrada.indexOf("R1=ON")>=0){ 
							digitalWrite(pinDigRele,HIGH) ;
							releAtivado=true ;
							lcd.cursorTo(2,0);
							lcd.printIn("Rele Ativado...");
							delay(30);
						}
						if(linhaEntrada.indexOf("R1=OF")>=0){ 
							// se a linha recebida contem GET e R1=OF enão guarde o status do rele
							digitalWrite(pinDigRele,LOW) ;
							releAtivado=false ;
							lcd.cursorTo(2,0);
							lcd.printIn("Rele Desativado....");
							delay(30);
						}                
					}
					linhaAtualvazia = true;
					linhaEntrada="" ;
				} else if (c != '\r') {
					// recebemos um carater que não é linefeed ou retorno de carro 
					// então recebemos um caracter e a linha de entrada não está mais vazia
					linhaAtualvazia = false;
				}             
			}
		}
		// dá 50 tempo para  o browser receber os caracteres
		delay(100);
		requisicaoHttp.stop();
	}else{
		if(exibe==1){
			lcd.cursorTo(2,0);
			lcd.printIn("SemConexao...");
			delay(50);
		}
	}
}
/*
* Metodo que inicia a a placa de rede.
*/
void iniciaRede(){
	Ethernet.begin(mac, ip, gt, snet); //iniciando a rede já habilita o ping
	delay(50);
}
/*
* Metodo que seta a hora no Chip RTC DS1302
*/
void setHora(){
	rtc.write_protect(false);
	rtc.halt(false);
	Time t(dta[0], dta[1], dta[2], dta[3], dta[4], dta[5], dta[6]);
	rtc.time(t);
}
/*
* Metodo que pega a hora, formata e imprimi no LCD.
*/
void impHora()
{
	snprintf(impdta, sizeof(impdta), "%04d-%02d-%02d %02d:%02d:%02d",t.yr,t.mon,t.date,t.hr,t.min,t.sec);
	lcd.printIn(impdta);
}
