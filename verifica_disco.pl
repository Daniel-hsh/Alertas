#!/usr/bin/perl -w

=pod
- VERIFICAR PORCENTAGEM DE USO DE MEMORIA CADA UM DOS BARRAMENTOS DO SERVIDOR
- CADA BARRAMENTO NAO PODE PASSAR DE 95% DE USO, SENAO ENVIA EMAIL
=cut

use lib 'lib';
use lib '/root/perl5/lib/perl5';
use lib '/home/wwwadm/perl5/lib/perl5/Text/Transliterator/';

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

our $dbh = DBI->connect("DBI:Pg:dbname="";host=$system_db_address", "", "",  { RaiseError => 1, AutoCommit => 0 });

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
	
	my $st = shift;
	my $html = "";
	my ($filesystem, $size, $used, $avail, $use, $mounted);

	$html .= "
<style>
   hr.style-two {
       border-top: 1px dashed #8c8b8b;
       border-bottom: 1px dashed #fff;
   }

   table {
      text-align: center;
      width: 100%;
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
                                    <img data-imagetype='External' width='140px'>
                                 </td>
                              </tr>
                              <tr>
								<td style='padding: 20px 40px 0px; font-family: proxima-nova, sans-serif;' bgcolor='#ffffff' align='left'>
										<table width='100%' style='background-color: rgb(255, 255, 255); padding: 0px; border: 0px none;'>
											<tbody>
												<tr>                                                        
													<td style='padding: 0px 0px 0px 40px;' align='center'>
														<p style='padding: 10px; max-width: 300px; border-radius: 40px; background-color: red; color: rgb(255, 255, 255); margin: 0px; font-size: 18px; line-height: 100%; text-align: center;'>
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
										Este alerta foi emitido no dia $diaAtual/$mesAtual/$anoAtual - $horaAtual:$minAtual:$secAtual pois alguma parti��o alcancou o limite de <strong>"; $html.=$st; $html.="</strong> dispon�vel. Por precau��o verifique as parti��es listadas.
									</td>
								</tr>
                           <tbody>
                        </table>
                     </td>
                  </tr>
                  <tr>
                     <td style='padding:4px 40px 0px 40px; font-family:proxima-nova ,sans-serif'; bgcolor='#ffffff' align='left'>              
                           <!--#############################
                              # FAZ UM LOOP PROS DADOS    #
                              #############################
                              # COLOCA AQUI SEUS TR E TD ##
                              #############################-->       
                        <table style='overflow-x:hidden; padding:0px; cellspacing:0; cellpadding:0; border-color: 1px; align:left; background-color: rgb(245, 245, 245)'>
                           <thead>
                              <tr>
                                 <th>Filesystem</th>
                                 <th>Tamanho</th>
                                 <th>Usado</th>
                                 <th>Disponivel</th>
                                 <th>Em Uso</th>
                                 <th>Montado</th>
                              </tr>
                           </thead>  
                           <tbody>";
                              # $html .= $dados;
							foreach my $row (@_) {
								$html .= "<tr>";
								($filesystem, $size, $used, $avail, $use, $mounted) = (split " ", $row)[0..5];

									$html .= "<td id='dado'>";
									$html .= $filesystem;
									$html .= "</td>";

									$html .= "<td id='dado'>";
									$html .= $size;
									$html .= "</td>";

									$html .= "<td id='dado'>";
									$html .= $used;
									$html .= "</td>";

									$html .= "<td id='dado'>";
									$html .= $avail;
									$html .= "</td>";

                           if($st =~ /Mem/){
                             $html .= "<td id='dado' style='background-color:red; color:white;'>";
                           }else{
                              $html .="<td id='dado'>";
                           }
									$html .= $use;
									$html .= "</td>";					
                          
                           $html .="<td id='dado'>";
									$html .= $mounted;
									$html .= "</td>";
												
									$html .= "</tr>";
							}							
                              $html .= "
                                       </tbody>
                        </table>
                     </td>
                  </tr>              
                  <tr>
                     <td style='margin:0px; padding:15px 40px 0px 40px' bgcolor='#ffffff'>
                        <table style='width:100%'>
                           <tbody>
                                 <tr>
                                    <td style='background:none; border-top:solid 1px #EAEAEF; border-left:none; border-right:none; border-bottom:none; border-collapse:collapse; border-spacing:0; width:100%; margin:0px 0px 0px 0px'>
                                    </td>
                                 </tr>
                              </tbody>
                        </table>
                     </td>
                  </tr>";             
   $html .= "<tr>
                     <td style='padding:40px 20px 0px 20px; font-family:proxima-nova sans-serif; border-bottom-left-radius:10px; border-bottom-right-radius:10px' bgcolor='#ffffff' align='left'>
                     </td>
                  </tr>
                  </tbody>
               </table>
            </td>
         </tr>
      </tbody>
   </table>
    "; 
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
	system("df -h | tail -n +2 > script/df_h.txt");
	my($filesystem, $use, $mounted);
	my @listaMemoria;
	my $sub = "Alerta de servidor";
	my $from = "<nopreply\@voesideral.com.br>";

	open (my $fh, "<script/df_h.txt" ) or die "Não foi possivel abrir o arquivo";
		while(my $row = <$fh>){
			($filesystem, $use, $mounted ) = (split " ", $row)[0, 4, 5];
			if($use ge '95%'){
				push (@listaMemoria, $row);
			}
		}
	close $fh;

	if(($#listaMemoria+1) > 0){
		my $sendEmailSuporte = SQL_listaEmailSistema($dbh);
		my $msg = FUNC_montaMsg("Memoria",@listaMemoria);
		foreach my $valores (@{$sendEmailSuporte}){  
			enviarEMAIL($msg, $sub, $from, $valores->{email});
		}
	}
}

main();
1;
