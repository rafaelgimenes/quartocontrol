package net.rafaelgimenes.quartocontrol;


import java.net.URI;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

/**
 * QuartoControl
 *07/10/2010
 *ClienteHttpGet.java
 *@author RafaelGimenesLeite - falecom@rafaelgimenes.net
 * 
 */
public class ClienteHttpGet implements Runnable {
    //usa pra executar
    String url="";
    /*
     * Próprio contrutor já requisita a url e inicia a Thread;
     */
    public ClienteHttpGet(String urlParam) {
        super();
        url=urlParam;
        System.out.println("url="+url);
        Thread t = new Thread(this);
        t.start();
    }
    
    //faz nada
    public void fim() {
     
    }
    
    /*
     * Método RUN da Thread;
     * */
    public void run() {
            //criando objeto Cliente
            HttpClient cliente = new DefaultHttpClient();
            //criando objeto requisicao GET
            HttpGet requiscao = new HttpGet();
            try {
                //Setando a url a ser executada
                requiscao.setURI(new URI(url));
                //Executando no objeto Cliente, detalhe este método retorna um HttpResponse mas não uso.
                cliente.execute(requiscao);
            } catch (Exception e) {
                e.printStackTrace();
            }
    }
}

/* 
 * Exemplo retirado da internet e enxugado e transformado em THread;
 * 
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
public class TestHttpGet {
    public void executeHttpGet() throws Exception {
        BufferedReader in = null;
        try {
            HttpClient client = new DefaultHttpClient();
            HttpGet request = new HttpGet();
            request.setURI(new URI("http://w3mentor.com/"));
            HttpResponse response = client.execute(request);
            in = new BufferedReader
            (new InputStreamReader(response.getEntity().getContent()));
            StringBuffer sb = new StringBuffer("");
            String line = "";
            String NL = System.getProperty("line.separator");
            while ((line = in.readLine()) != null) {
                sb.append(line + NL);
            }
            in.close();
            String page = sb.toString();
            System.out.println(page);
            } finally {
            if (in != null) {
                try {
                    in.close();
                    } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
*/
