#!/usr/bin/perl -w

=pod
- VERIFICAR SE OS PROCESSOS DO SERVIDOR DE ESTÃO RODANDO HÝ MUITO TEMPO E CONSUMINDO MAIS DE 90% DE MEMORIA E CPU
- CADA REQUISICAO OU SERVICO, NÃO DEVE DEMORAR MAIS QUE 60 SEG.
- SE TEMPO >=120 SEG. -> EMITIR ALERTA
- VERIFICA TODOS OS PROCESSOS EMITIDOS PELO TOP DO LINUX
- É AGENDADA NO CRON PARA RODAR A CADA 5MIN (SCHEDULE)
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
	
	my $st = shift;
   my $general_us_cpu = shift;
   my $general_us_mem = shift;
	my $html = "";
	my ($pid, $user, $pr, $status, $cpu, $mem, $time, $command);

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
										Este alerta foi emitido no dia $diaAtual/$mesAtual/$anoAtual - $horaAtual:$minAtual:$secAtual pois algum processo(s) est&eacute; consumindo <strong>"; $html.=$st; $html.="</strong> Verifique a disponibilidade dos servi&ccedil;os que est&atilde;o rodando.
									</td>
								</tr>
                        <tr>
									<td style='padding: 20px 40px 0px; font-family: proxima-nova, sans-serif;' bgcolor='#ffffff' align='justify'>
                              ";
                           $html .= $general_us_cpu;
                           $html .= $general_us_mem;
									$html .= "</td>
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
                                 <th>PID</th>
                                 <th>USER</th>
                                 <th>PR</th>
                                 <th>STATUS</th>
                                 <th>CPU</th>
                                 <th>MEM</th>
                                 <th>TEMPO REQ.</th>
								 <th>COMMAND</th>
                              </tr>
                           </thead>  
                           <tbody>";
                              # $html .= $dados;
							foreach my $row (@_) {
								$html .= "<tr>";
								($pid, $user, $pr, $status, $cpu, $mem, $time, $command) = (split " ", $row)[0..2, 7..11];

									$html .= "<td id='dado'>";
									$html .= $pid;
									$html .= "</td>";

									$html .= "<td id='dado'>";
									$html .= $user;
									$html .= "</td>";

									$html .= "<td id='dado'>";
									$html .= $pr;
									$html .= "</td>";

									$html .= "<td id='dado'>";
									$html .= $status;
									$html .= "</td>";

                           if($st eq 'CPU'){
                             $html .= "<td id='dado' style='background-color:red; color:white;'>";
                           }else{
                              $html .="<td id='dado'>";
                           }
									$html .= $cpu;
									$html .= "</td>";
													
                           if($st eq 'Memoria'){
                              $html .= "<td id='dado' style='background-color:red; color:white;'>";
                           }else{
                              $html .="<td id='dado'>";
                           }
									$html .= $mem;
									$html .= "</td>";
														
                           if($st eq 'tdr'){
                              $html .="<td id='dado' style='background-color:red; color:white;'>"
                           }else{
                              $html .="<td id='dado'>";
                           }
									$html .= $time;
									$html .= "</td>";

									$html .= "<td id='dado'>";
									$html .= $command;
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

sub registraLOG {
   my ($pid, $datestring, $status_proc, $tree);
   $datestring = localtime();
   open(my $st, ">>script/log/status_processo.txt") or die "Nao foi possivel abrir o arquivo";
      foreach my $value (@_){  ###Printar o ID do processo!
         ($pid) = (split " ", $value)[0];
         $status_proc = `cat /proc/$pid/status`;
         $tree = `pstree -p -s -n $pid`;
         
         print $st "$datestring\n";
         print $st "$pid - STATUS\n";
         print $st "$status_proc\n";
         print $st "ARVORE COMANDO $pid\n";
         print $st "$tree\n";
         print $st "======================================================================"
      }
   close $st;
}

sub main(){
	system("top -bn1 > script/processo_tmp.txt"); # | tail -n +11
   my $data_cpu = `cat script/processo_tmp.txt | grep Cpu`;
   my $data_mem = `cat script/processo_tmp.txt | grep Mem`;
   system("sed '1,11 d' script/processo_tmp.txt > script/processo.txt");
   system("rm script/processo_tmp.txt");

	my($pid, $cpu, $mem, $time, $command);
	my (@listaCPU, @listaTime, @listaMem);
	my $sub = "Alerta de servidor";
	my $from = "<nopreply\@voesideral.com.br>";

	open (my $fh, "<script/processo.txt" ) or die "Nao foi possivel abrir o arquivo";
		while(my $row = <$fh>){
			($pid, $cpu, $mem, $time, $command) = (split " ", $row)[0,8..11]; #coluna 11 -> command
         if(   $command =~ 'gnome'        || $command =~ 'systemd'      || 
               $command =~ 'kswapd0'      || $command =~ 'rcu_sched'    ||
               $command =~ 'xfsaild'      || $command eq 'rngd'         ||
               $command =~ 'avahi'        || $command eq 'ksmtuned'     ||
               $command eq 'uwsgi'        || $command =~ 'mysqld'       ||
               $command =~ 'package'      || $command =~ 'dbus'         || 
               $command eq 'lvmetad'      || $command =~ 'perl'         ||
               $command =~ 'postmaster'   || $command =~ 'posgres'      ||
               $command =~ 'jbd'          || $command =~ 'daemon'       ||
               $command eq 'polkitd'      || $command eq 'gsd-color'    ||
               $command eq 'irqbalance'   || $command eq 'gzip'         ||
               $command eq 'tuned'        || $command eq 'nginx'        ||
               $command eq 'rsyslogd'     || $command eq 'master'       || 
               $command eq 'NetworkMa+'   || $command eq 'NetworkManager' ||
               $command =~ 'ksoftirqd'    || $command eq 'crond'          ||
               $command eq 'X'            || $command =~ 'ibus-daem+' ||
		$command eq 'qmgr'	  || $command eq 'sshd'       ||
		$command eq 'rtkit-dae+'  || $command eq 'accounts-+' || 
		$command eq 'boltd'	  || $command =~ 'gsd'		||
		$command eq 'audispd'){
            next;
         }else{
            if($cpu gt '90,0'){
               push (@listaCPU, $row);
            }
            if($mem gt '95,0'){
               push (@listaMem, $row);
            }
            if($time gt '2:00.00'){
               push (@listaTime, $row);
            }
         }
      }
	close $fh;

   if(@listaMem){
      my $sendEmailSuporte = SQL_listaEmailSistema($dbh);
      registraLOG(@listaCPU);
      my $msg = FUNC_montaMsg("CPU", $data_cpu, $data_mem, @listaCPU);
      foreach my $valores (@{$sendEmailSuporte}){  
         enviarEMAIL($msg, $sub, $from, $valores->{email});
      }
   }

   if(@listaMem){
      my $sendEmailSuporte = SQL_listaEmailSistema($dbh);
      registraLOG(@listaMem);
      my $msg = FUNC_montaMsg("Memoria", $data_cpu, $data_mem, @listaMem);
      foreach my $valores (@{$sendEmailSuporte}){  
         enviarEMAIL($msg, $sub, $from, $valores->{email}); 
      }
   }

	if (@listaTime){ #($#listaTime+1) > 0
		my $sendEmailSuporte = SQL_listaEmailSistema($dbh);
      registraLOG(@listaTime);
		my $msg = FUNC_montaMsg("tdr", $data_cpu, $data_mem, @listaTime);
		foreach my $valores (@{$sendEmailSuporte}){  
			enviarEMAIL($msg, $sub, $from, $valores->{email});
		}
	}
}
main();
1;

#######
# - POSSIVEL FEATURE FUTURA:
#######
