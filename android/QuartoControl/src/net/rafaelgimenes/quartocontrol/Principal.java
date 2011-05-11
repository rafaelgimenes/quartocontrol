package net.rafaelgimenes.quartocontrol;

import net.rafaelgimenes.quartocontrol.R;
import android.view.*;
import android.app.AlertDialog;
import android.app.Activity;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.widget.*;

/**
 * QuartoControl
 *07/10/2010
 *Pincipal.java
 *@author RafaelGimenesLeite - falecom@rafaelgimenes.net
 * 
 */ 
public class Principal extends Activity implements SensorEventListener {
    /** Called when the activity is first created. */
    //variaveis de controles usadas no Sensor de Movimento
    private SensorManager sensorMgr;    
    private long ultimoUpdate = -1;
    private float x, y, z;
    private float ant_x, ant_y, ant_z;
    private static final int SHAKE_THRESHOLD = 800;
    private boolean acesa=false; 
    private int cnt=0;
       
    
    //Declarando objetos que vão interagir com o layout xml;
    public static EditText txtLCD = null; // caixa de texto
    public static CheckBox ChkLuz = null; // check 
    
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        sensorMgr = (SensorManager) getSystemService(SENSOR_SERVICE);
        boolean accelSupported = sensorMgr.registerListener(this,sensorMgr.getDefaultSensor(SensorManager.SENSOR_ACCELEROMETER),SensorManager.SENSOR_DELAY_GAME);
        if (!accelSupported) {
        // non accelerometer on this device
            sensorMgr.unregisterListener(this); 
        }
        //simulando q nao tem sensor
        sensorMgr.unregisterListener(this); 
        
        //seta o layout (lê o layout do arquivo) Main.xml
        setContentView(R.layout.main);
        
        //instancia o TxtLcd buscando informações de propriedade no arquivo main.xml;
        txtLCD = (EditText) findViewById(R.id.txtLCD);
        //limpando a caixa
        txtLCD.setText("");
        
        //instancia o ChkLuz buscando informações de propriedade no arquivo main.xml;
        ChkLuz = (CheckBox) findViewById(R.id.chkLuzOnOff);
        //criando um evento no click do check;
        ChkLuz.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                if(ChkLuz.isChecked()) {
                    //envia comando; ON
                        ClienteHttpGet clienteON = new ClienteHttpGet("http://10.0.0.20:9703/R1=ON");
                        clienteON.fim();
                        acesa=true;
                        /*AlertDialog.Builder dialogo = new AlertDialog.Builder(Principal.this); //dialogo geral
                        dialogo.setTitle("Comando Enviado");
                        dialogo.setMessage("Em instantes a lampada sera acesa.");
                        dialogo.setNeutralButton("OK", null);
                        dialogo.show();*/
                    
                }else {
                        ClienteHttpGet clienteOFF = new ClienteHttpGet("http://10.0.0.20:9703/R1=OF");
                        clienteOFF.fim();
                        /*AlertDialog.Builder dialogo = new AlertDialog.Builder(Principal.this); //dialogo geral
                        dialogo.setTitle("Comando Enviado");
                        dialogo.setMessage("Em instantes a lampada sera apagada.");
                        dialogo.setNeutralButton("OK", null);
                        dialogo.show();*/
                        acesa=false;
                }
                
            }
        });
                
        //criando e associando o botão com o layout
        Button btnLCD = (Button) findViewById(R.id.btnLCD); 
        //criando evento no click do botão
        btnLCD.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                
                //mudando String por _
                String nStr = txtLCD.getText() + "";
                nStr = nStr.replace(" ","_");
                    
                
                ClienteHttpGet clienteTxtLcd = new ClienteHttpGet("http://10.0.0.20:9703/TL=" + nStr  );
                clienteTxtLcd.fim();
                //chamando uma mensagem de alerta
                AlertDialog.Builder dialogo = new AlertDialog.Builder(Principal.this); //dialogo geral
                dialogo.setTitle("Comando Enviado para o LCD");
                dialogo.setMessage(""+txtLCD.getText());
                dialogo.setNeutralButton("OK", null);
                dialogo.show();
                
               
                
            }
        });
                
        
        
    }

    /* (non-Javadoc)
     * @see android.hardware.SensorEventListener#onAccuracyChanged(android.hardware.Sensor, int)
     */
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // TODO Auto-generated method stub
        
    }
    
    public void onSensorChanged(SensorEvent event) {
        Sensor celSensor = event.sensor;
            if (celSensor.getType() == SensorManager.SENSOR_ACCELEROMETER) {
                long tempoAgora = System.currentTimeMillis();
                
                // only allow one update every 100ms.
                if (((tempoAgora - ultimoUpdate) > 300)) {
                    long diffTime = (tempoAgora - ultimoUpdate);
                    ultimoUpdate = tempoAgora;
                   
                    x = event.values[SensorManager.DATA_X];
                    y = event.values[SensorManager.DATA_Y];
                    z = event.values[SensorManager.DATA_Z];

                    float speed = Math.abs(x+y+z - ant_x - ant_y - ant_z)/ diffTime * 10000;
                    //passa que é seu faz o necessário
                    if ((speed > SHAKE_THRESHOLD) ) {
                       
                      
                        cnt++;
                        if(!acesa) {
                            ClienteHttpGet clienteON = new ClienteHttpGet("http://10.0.0.20/R1=ON");
                            clienteON.fim();
                            acesa=true;
                            Principal.ChkLuz.setSelected(true);
                            Principal.txtLCD.setText("ACENDEU");
                            
                            
                        }else {
                            ClienteHttpGet clienteOF = new ClienteHttpGet("http://10.0.0.20/R1=OF");
                            clienteOF.fim();
                            acesa=false;
                            Principal.ChkLuz.setSelected(false);
                            Principal.txtLCD.setText("APAGOU");
                            Principal.ChkLuz.setText(".");
                        }
                        
                       
                        
                    }
                        ant_x = x;
                        ant_y = y;
                        ant_z = z;
                       
                    }
               }           
     }
    
}