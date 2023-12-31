<?php
// API

function getDb(){
  $pdo=new PDO('sqlite:immunia_levelgen.db');
  $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
  return $pdo;
}

// Write new level
if(isset($_POST['state'])&&isset($_POST['win_moves'])){
  $pdo=getDb();
  $q='insert into levels(state,win_moves) values(?,?)';
  $s=$pdo->prepare($q);
  $s->execute([$_POST['state'],$_POST['win_moves']]);
  exit;
}

// Get unrated level
if(isset($_GET['rate'])){
  $pdo=getDb();
  $q='select rowid,* from levels where rating is null limit 1';
  $s=$pdo->prepare($q);
  $s->execute();
  $r=$s->fetch();
  echo json_encode($r);
  exit;
}

// Get number of playable levels
if(isset($_GET['num_playable'])){
  $pdo=getDb();
  $q='select count(*) as num_playable from levels where rating>0';
  $s=$pdo->prepare($q);
  $s->execute();
  $r=$s->fetch();
  echo json_encode($r);
  exit;
}

// Write rating
if(isset($_POST['rowid'])&&isset($_POST['rating'])){
  $pdo=getDb();
  $q='update levels set rating=? where rowid=?';
  $s=$pdo->prepare($q);
  $s->execute([$_POST['rating'],$_POST['rowid']]);
  exit;
}

// Get Level Fix
if(isset($_GET['level_fix'])){
  $pdo=getDb();
  $q='select rowid,* from levels where rating>0 and difficulty is null order by rating asc, rowid asc limit 1';
  $s=$pdo->prepare($q);
  $s->execute();
  $r=$s->fetch();
  echo json_encode($r);
  exit;
}

// Set Level Fix
if(isset($_POST['rowid'])&&isset($_POST['difficulty'])&&isset($_POST['state_improved'])){
  $pdo=getDb();
  $q='update levels set difficulty=?, state_improved=? where rowid=?';
  $s=$pdo->prepare($q);
  $s->execute([$_POST['difficulty'],$_POST['state_improved'],$_POST['rowid']]);
  exit;
}

// Get number of fixed levels
if(isset($_GET['num_fixed'])){
  $pdo=getDb();
  $q='select count(*) as num_fixed from levels where difficulty is not null';
  $s=$pdo->prepare($q);
  $s->execute();
  $r=$s->fetch();
  echo json_encode($r);
  exit;
}

// Get levels in order
if(isset($_GET['levels_in_order'])){
  $pdo=getDb();
  $q='select * from levels where rating>0 and difficulty is not null order by difficulty asc, rating asc, rowid asc';
  $s=$pdo->prepare($q);
  $s->execute();
  $r=$s->fetchAll();
  echo json_encode($r);
  exit;
}

// Misc tools...
if(isset($_GET['tools'])){
  $pdo=getDb();
  $out='';
  header('content-type:text/plain');

  // Import
  if(false){
    $json=json_decode(file_get_contents('./add_unrated.json'),true);
    foreach($json as $d){
      $q='select * from levels where state=?';
      $s=$pdo->prepare($q);
      $s->execute([$d['state']]);
      $r=$s->fetch();
      if($r){
        echo 'state already exists: '.$d['state'].' ...skipping!'.PHP_EOL;
      }else{
        $q='insert into levels(state,win_moves) values(?,?)';
        $s=$pdo->prepare($q);
        $s->execute([$d['state'],$d['win_moves']]);
        echo 'state inserted: '.$d['state'].' '.PHP_EOL;
      }
      echo PHP_EOL.PHP_EOL;
    }
    exit;
  }

  // Get unrated JSON
  if(false){
    $q='select * from levels where rating is null';
    $s=$pdo->prepare($q);
    $s->execute();
    $r=$s->fetchAll();
    $out=json_encode($r,JSON_PRETTY_PRINT);
    echo $out;
  }

  // Get all levels in order...
  if(true){
    $q='select * from levels where rating>0 and difficulty is not null order by difficulty asc, rating asc, rowid asc';
    $s=$pdo->prepare($q);
    $s->execute();
    $r=$s->fetchAll();
    $out='';
    foreach($r as $d){
      $out.=$d['state_improved']."\n";
    }
  }

  // longest soluition length in db
  if(false){
    $q='select * from levels where rating>0';
    $s=$pdo->prepare($q);
    $s->execute();
    $r=$s->fetchAll();
    $longest='';
    foreach($r as $d){
      $a=json_decode($d['win_moves'],true);
      foreach($a as $w){
        if(strlen($w)>strlen($longest)){
          $longest=$w;
        }
      }
    }
    $out='longest solution: '.$longest;
  }

  // Output
  echo $out;
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
    letter-spacing: 2px;
}
.up {
    position: absolute;
    left: 33%;
    top: 8%;
    transform: rotate(-90deg);
    text-align: center;
    width: 35px;
}
.down {
    position: absolute;
    left: 33%;
    bottom: 8%;
    transform: rotate(-90deg);
    text-align: center;
    width: 35px;
}
.left {
    position: absolute;
    top: 40%;
    left: 3%;
}
.right {
    position: absolute;
    top: 40%;
    right: 3%;
}
#cell-edit {
    width: 300px;
    height: 300px;
    float: right;
    margin: 10px 20px;
    background: #333;
    padding: 20px;
}
button{
    padding:5px;
    font-size:14px;
}
hr {
    border: none;
    background: none;
    border-bottom: 1px solid #444;
    border-top: 1px solid #111;
}
#cell-edit label{
    display:inline-block;
    margin:5px;
    padding:5px;
    width:110px;
    font-weight:bold;
    cursor:pointer;
}
label.select-wbc{
    background: #529eff;
    color:#222;
}
label.select-bacteria{
    background: #9b3131;
    color:#222;
}
label.select-blocked{
    background: black;
}
.edit-shields {
    position:relative;
    height:80px;
}
.edit-shields input{
    width:55px;
    padding:2px;
    font-weight:bold;
    color:#eee;
    background:#444;
    font-size:16px;
}
#edit-up-shield{
    position:absolute;
    top:0;
    left:102px;
}
#edit-down-shield{
    position:absolute;
    bottom:0;
    left:102px;
}
#edit-left-shield{
    position:absolute;
    top:30px;
    left:30px;
}
#edit-right-shield{
    position:absolute;
    right:30px;
    top:30px;
}
#edit-loc {
    color: #f0e986;
    font-size: 20px;
}
label:has(input[type="radio"]:checked) {
    outline:5px solid #f0e986;
}
.cell.active {
    outline: 5px solid #f0e986;
}
#rate-rowid{
  color:#f0e986;
}
select#rate-send {
    font-size: 20px;
    padding: 4px;
}
div#rate-send {
    display: inline;
}
span.tiny-note {
    font-size: smaller;
    color: #e4beef;
}
small{
  color:goldenrod;
}
</style>
</head>
<body>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.1/jquery.min.js"></script>

<div id="page">

  <div id="cell-edit">
    <div id="edit-loc"></div>
    <hr />
    <label class="select-empty"><input type="radio" name="edit-type" value="empty" />empty</label>
    <label class="select-wbc"><input type="radio" name="edit-type" value="wbc" />wbc</label>
    <label class="select-bacteria"><input type="radio" name="edit-type" value="bacteria" />bacteria</label>
    <label class="select-blocked"><input type="radio" name="edit-type" value="blocked" />blocked</label>
    <hr />
    <div class="edit-shields">
      <input id="edit-up-shield" type="number" min="0" max="3" step="1" />
      <input id="edit-down-shield" type="number" min="0" max="3" step="1" />
      <input id="edit-left-shield" type="number" min="0" max="3" step="1" />
      <input id="edit-right-shield" type="number" min="0" max="3" step="1" />
    </div>
  </div>

  <div id="game"></div>

  <hr />

  <p>
    <a href="#random_play">Generate Random and Play</a><br />
    <textarea id="playstring" rows="1" cols="80"></textarea>
  </p>

  <p>
    <label>Load State String</label>
    <textarea id="statestring" rows="1" cols="80"></textarea>
    <button id="load">Load</button>
  </p>

  <p>
    <a href="#level_fix">Level Fix</a> <small><span id="num-fixed"></span></small><br />
    <textarea rows="10" cols="80" id="level_fix_output"></textarea>
  </p>

  <p>
    <a href="#verify_levels">Verify Levels</a><br />
  </p>

  <p>
    <a href="#levelgen_single">Run Levelgen Program Once</a>
  </p>

  <p>
    <a href="#levelgen">Run Levelgen Program Continuous</a>
  </p>
  
  <p>
    <a href="#play_and_rate">Play and Rate</a><br />
    <small>(Note: This should be N/A with the new Level Fix routine...)</small><br />
    <div id="rate-rowid"></div>
    <div id="rate-send"></div> <span class="tiny-note">You can also rate with 0-9 keys...</span>
  </p>

</div>

<script src="immunia_levelgen.js"></script>

</body>
</html>
