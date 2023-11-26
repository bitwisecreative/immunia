<?php
// API data write
if(isset($_POST['state'])&&isset($_POST['win_moves'])){
  $pdo=new PDO('sqlite:immunia_levelgen.db');
  $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
  $q='insert into levels(state,win_moves) values(?,?)';
  $s=$pdo->prepare($q);
  $s->execute([$_POST['state'],$_POST['win_moves']]);
  exit;
}
?>
<!doctype html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Immunia Brute Force Levelgen :(</title>
<style>
html {
  box-sizing: border-box;
}
*, *:before, *:after {
  box-sizing: inherit;
}
body{
  background:#222;
  color:#333;
  font-family:consolas,monospace;
}
#game {
    position: relative;
    margin: 20px;
    width: 484px;
    height: 484px;
}
a {
    color: #8fa6cb;
}
label{
  color:#aaa;
  display:block;
}
button {
    display: block;
}
textarea {
    margin: 5px 0;
    padding: 5px;
    background: #234;
    color: #abc;
}
.cell {
    width: 100px;
    height: 100px;
    position: absolute;
    background: #333;
}
.cell.blocked {
    background: #111;
}
.cell.bacteria {
    background: #9b3131;
}
.cell.wbc {
    background: #529eff;
}
.shield {
    font-weight: bold;
}
.up {
    position: absolute;
    left: 44%;
}
.down {
    position: absolute;
    left: 44%;
    bottom: 0;
}
.left {
    position: absolute;
    top: 38%;
    left: 2px;
}
.right {
    position: absolute;
    top: 38%;
    right: 2px;
}
</style>
</head>
<body>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.1/jquery.min.js"></script>

<div id="page">

  <div id="game"></div>

  <hr />

  <p>
    <a href="#random_play">Generate Random and Play</a><br />
    <textarea id="playstring" rows="1" cols="80"></textarea>
  </p>

  <p>
    <a href="#levelgen_single">Run Levelgen Program Once</a>
  </p>

  <p>
    <a href="#levelgen">Run Levelgen Program Continuous</a>
  </p>

  <p>
    <label>Load State String</label>
    <textarea id="statestring" rows="1" cols="80"></textarea>
    <button id="load">Load</button>
  </p>

</div>

<script src="immunia_levelgen.js"></script>

</body>
</html>