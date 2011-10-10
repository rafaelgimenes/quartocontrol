<?php
/*
 * Processa email, requisicao vinda do arduino
 * Autor: Rafael Gimenes Leite - falecom@rafaelgimenes.net
*/
$ip = $_SERVER['REMOTE_ADDR'];
$para = 'falecom@rafaelgimenes.net';
$assunto = 'Alerta E-mail '  . $_REQUEST['A']; 
$corpo = 'Email enviado, do quarto do Rafael Gimenes motivo:  ' . $_REQUEST['A']  ;
$corpo = $corpo . ' Opções para Susto  ';
$corpo = $corpo . ' http://' . $ip . ':9703/R1=OF';
$corpo = $corpo . '               http://' . $ip . ':9703/R1=ON';
$corpo = $corpo . '\n Mensagem automática :) QuartoControl V1 ';
$headers = "From: Quarto@rafaelgimenes.net";
if($_REQUEST['E']=='1'){
	$mail_sent = @mail( $para, $assunto, $corpo, $headers );
	echo $mail_sent ? "Email OK " : " EMAIL NÃO OK ";
}else
	echo "Não OK";
?>
