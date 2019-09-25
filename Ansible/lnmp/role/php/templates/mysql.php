<?php
$link=mysql_connect('192.168.122.235','root','');
if ($link)
              echo "Successfully";
else
              echo "Failed";
mysql_close();
?>

