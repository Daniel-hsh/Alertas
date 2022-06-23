#!/usr/local/bin/perl -w

=pod
- VERIFICAR SE SERVIDOR DE PRODUCAO ESTA DESLIGADO
- EMITE 5 PACOTES DE PING DE 1ms PARA TESTAR O SERVIDOR
- MANDA REQUISIÇÃO HTTP
- EMITE PARECER SE CONEXAO ESTAO OK OU MEIO OCIOSA TAMBEM EM CASO DE CONEXÃO COM SUCESSO;
- PROD <- 86 / BACKUP <- PROD
=cut

use lib 'lib';
use lib '/root/perl5/lib/perl5';

use strict;
use warnings;
use CGI qw/:standard/;
use IO::Socket;
use Data::Dumper;
use DateTime;
use DBI;

use MIME::Lite;
use Net::SMTPS;
use Try::Tiny;
use MAIL_sidcontrol;

my $system_db         = "";
my $system_db_address = "";
my $system_db_user    = "";
my $system_db_pass    = "";
my $sys    			    = "";

our $dbh = DBI->connect("DBI:Pg:dbname=;host=$system_db_address", "", "",  { RaiseError => 1, AutoCommit => 0 });


sub FUNC_montaMsg {
	my $timeZone = 'America/Sao_Paulo';
	my $data_de_hoje = DateTime->now( time_zone => 'local' )->set_time_zone($timeZone);
	my $diaAtual  =  ($data_de_hoje->day()   < 10 ? "0".$data_de_hoje->day()   : $data_de_hoje->day() );
	my $mesAtual  =  ($data_de_hoje->month() < 10 ? "0".$data_de_hoje->month() : $data_de_hoje->month()  );
	my $anoAtual  =  $data_de_hoje->year();
	#hora/min/sec atuais
	my $horaAtual = ($data_de_hoje->hour < 10 ? "0".$data_de_hoje->hour : $data_de_hoje->hour);
	my $minAtual = ($data_de_hoje->minute < 10 ? "0".$data_de_hoje->minute : $data_de_hoje->minute);
	my $secAtual = ($data_de_hoje->second < 10 ? "0".$data_de_hoje->second : $data_de_hoje->second);
	#linhateste: print Dumper \%hash;
	my $html ="
	<style>
   hr.style-two {
       border-top: 1px dashed #8c8b8b;
       border-bottom: 1px dashed #fff;
   }
   
   table thead th {
      text-align: center;
      border: 1px solid black
   }

   table tbody #dado {
      height: 3em;
      border-bottom: 1px solid rgb(183, 180, 212);
   }
	</style>

	<table style='background-color:#EAEAEF;overflow-x:hidde; width:100%; cellspacing:0 cellpadding;0 border:0'>
	   <tbody>
			<tr>
				<td align='left'>
					<table style='border-collapse:collapse;margin-top:10px;margin-bottom:10px; overflow-x:hidden; font-family:proxima-nova sans-serif; width:95%; max-width:600px' cellspacing='0' cellpadding='0' border='0' align='center'>
						<tbody>
							<tr>
								<td align='center' COLSPAN=3>
									<table width='100%' style='overflow-x:hidden;background-color:#FFFFFF;cellspacing:0;cellpadding:0;border:0;align:center' >
										<tbody>
											<tr>
												<td style='padding:20px 20px 20px 20px;text-align:center; font-family:proxima-nova sans-serif;' align='center'>
													<img data-imagetype='External'  width='140px'>
												</td>
											</tr>
											<tr>
												<td style='padding: 20px 40px 0px; font-family: proxima-nova, sans-serif;' bgcolor='#ffffff' align='left'>
													<table width='100%' style='background-color: rgb(255, 255, 255); padding: 0px; border: 0px none;'>
														<tbody>
															<tr>                                                        
																<td style='padding: 0px 0px 0px 40px;' align='center'>
																	<p style='padding: 10px; max-width: 300px; border-radius: 40px; background-color: rgb(228, 16, 16); color: rgb(255, 255, 255); margin: 0px; font-size: 18px; line-height: 100%; text-align: center;'>
																		<span class='Object' role='link' id='OBJ_PREFIX_DWT192_com_zimbra_url'><a style='color: white;' href='#' rel='nofollow noopener noreferrer nofollow noopener noreferrer' target='_blank'>ALERTA</a></span>
																	</p>
																</td>
															</tr>
														</tbody>
													</table>
												</td>
											</tr>
											<tr>
												<td style='padding: 20px 40px 0px; font-family: proxima-nova, sans-serif;' bgcolor='#ffffff' align='justify'>
													Este alerta foi emitido pois o servidor de PRODUCAO (172.21.0.83) aparenta estar desligado. Verifique a disponibilidade do servidor e d&ecirc; start.
												</td>
											</tr>
											<tr>
												<td style='padding: 20px 40px 0px; font-family: proxima-nova, sans-serif;' bgcolor='#ffffff' align='left'>
                                                    <p> <strong>HOST EMISSOR:</strong> 172.21.0.86</p>
													<p> <strong>HOST RECEPTOR:</strong> PRODUCAO</p>
													<p> <strong>DATA/HORA: </strong> ";
													$html .= "$diaAtual/$mesAtual/$anoAtual - Hora $horaAtual:$minAtual:$secAtual";
													
													$html.="</p>
													<p style='padding-top: 5px; border-top: 1px solid;'></p>
												</td>
											</tr>
										</tbody>
									</table>
								</td>
							</tr>
						</tbody>
					</table>
				</td>
			</tr>
		</tbody>
	</table>";
	return $html;
}

sub SQL_listaEmailSistema {  
    my ($dbh) = @_;
    my $listaSlice = [];

    my $sql = "";
 						
	eval { $listaSlice = $dbh->selectall_arrayref( $sql, { Slice=>{} } ) or die; };
	
	if ($@) {
      warn "Transaction aborted because $@";
	}

   return $listaSlice;
}

sub main(){
	my $hostname = ''; 
	my $pacotes = 5;
	my $sub = "Ambiente teste 086 - Alerta de servidor";
	my $from = "<nopreply\@voesideral.com.br>";

	my $status = `ping -c $pacotes $hostname | grep '64 bytes' | wc -l`;
	if( $status == $pacotes ){
		print "Servidor de BACKUP ok\n";
	}elsif( $status >= 1 && $status<=3 ){
		print "Servidor ok, Canal ocioso\n";
	}elsif( $status == 0 ){
		print "Servidor parece estar desligado...\n";
		my $sendEmailSuporte = SQL_listaEmailSistema($dbh);
		foreach my $valores (@{$sendEmailSuporte}){  
			enviarEMAIL(FUNC_montaMsg(), $sub, $from, $valores->{email});
		}
	}else{
		print "Erro! Saindo...\n"; exit;
	}
	
}
main();
1;
