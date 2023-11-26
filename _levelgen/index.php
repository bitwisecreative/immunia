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

  <div id="game">

  </div>

</div>

<script>
$(function(){


  // grid
  gsx=4;
  gsy=4;
  spritesize=128;
  cells=[];

  let str='w1232,b3212,e,e,e,x,e,e,e,e,x,e,x,e,e,e';
  //state_string(str);

  gen_random_board();
  state_string();
  draw_board();

  //
  // EVENTS
  //
  $(document).on('keyup',function(e){
    switch(e.key){
      case 'ArrowUp':
        move(0,-1);
        break;
      case 'ArrowDown':
        move(0,1);
        break;
      case 'ArrowLeft':
        move(-1,0);
        break;
      case 'ArrowRight':
        move(1,0);
        break;
    }
  });

  //
  // FUNCTIONS
  //

  // build state from string, or return current state as string
  function state_string(str){
    if(str){
      console.log(str);
      let a=str.split(',');
      if(a.length!=gsx*gsy){
        throw new Error('State string: invalid length.');
      }
      cells=[];
      let tok=['e','x','w','b'];
      for(let i=0;i<a.length;i++){
        let x=(i%gsx)+1;
        let y=(Math.floor(i/gsy))+1;
        console.log(x,y);
        let t=a[i].substring(0,1);
        console.log(t);
        if(tok.indexOf(t)<0){
          throw new Error('State string: invalid type.');
        }
        // shields
        if(t=='w'||t=='b'){
          if(a[i].length!==5){
            throw new Error('State string: invalid cell data (shield).');
          }
          let type='wbc';
          if(t=='b'){
            type='bacteria';
          }
          let shield=[0,0,0,0];
          for(s=0;s<4;s++){
            let v=+a[i].substring(s+1,s+2);
            shield[s]=v;
          }
          let cell=gen_cell(type,x,y);
          cell.s=shield;
          cells.push(cell);
        }
        if(t=='x'){
          let cell=gen_cell('blocked',x,y);
          cells.push(cell);
        }
      }
    }else{
      let out=[];
      for(y=0;y<gsy;y++){
        for(x=0;x<gsx;x++){
          let cx=x+1;
          let cy=y+1;
          let cell=get_cell_at(cx,cy);
          if(cell){
            let v='';
            if(cell.t=='blocked'){
              v='x';
            }
            if(cell.t=='wbc'){
              v='w';
            }
            if(cell.t=='bacteria'){
              v='b';
            }
            if(cell.t=='wbc'||cell.t=='bacteria'){
              v+=cell.s.join('');
            }
            out.push(v);
          }else{
            out.push('e');
          }
        }
      }
      let outstr=out.join(',');
      console.log(outstr);
      return outstr;
    }
  }

  function gen_random_board(){
    // cell counts
    let nblocked=rint(0,3);
    let nwbc=rint(1,6);
    let nbacteria=rint(1,7);
    // place cells
    for(i=0;i<nblocked;i++){
      place_random('blocked');
    }
    for(i=0;i<nwbc;i++){
      place_random('wbc');
    }
    for(i=0;i<nbacteria;i++){
      place_random('bacteria');
    }
    // wbc no shields... chance to add random
    cells.forEach((e)=>{
      if(e.t=='wbc'){
        for(i=0;i<4;i++){
          if(rint(1,3)==1){
            e.s[i]=rint(1,3);
          }
        }
      }
    });
    // bacteria full shields... chance to remove random
    cells.forEach((e)=>{
      if(e.t=='bacteria'){
        e.s=[3,3,3,3];
        for(i=0;i<4;i++){
          if(rint(1,3)==1){
            e.s[i]-=rint(1,3);
          }
        }
      }
    });
  }

  function gridloop(x,y){
    if(x>gsx){
      x=1;
    }
    if(x<1){
      x=gsx;
    }
    if(y>gsy){
      y=1;
    }
    if(y<1){
      y=gsy;
    }
    return [x,y];
  }

  function move(x,y){
    console.log('move: '+x+','+y);
    // set all cell.p to 0 (unprocessed)
    cells.forEach((e)=>{
      e.p=0;
    });
    // move wbcs (multiple iterations...)
    function all_wbcs_move_processed(){
      let all_moved=true;
      cells.forEach((e)=>{
        if(e.t=='wbc'){
          if(e.p==0){
            all_moved=false;
            return;
          }
        }
      });
      return all_moved;
    }
    while(!all_wbcs_move_processed()){
      cells.forEach((e)=>{
        if(e.t=='wbc' && e.p==0){
          console.log(e.x,e.y,e.x+x,e.y+y,gridloop(e.x+x,e.y+y));
          let tloc=gridloop(e.x+x,e.y+y);
          let tx=tloc[0];
          let ty=tloc[1];
          let target=get_cell_at(tx,ty);
          if(!target){
            e.p=1;
            e.x=tx;
            e.y=ty;
          }else{
            // can't move
            if(target.t=='blocked'||(target.t=='wbc'&&target.p>0)){
              e.p=2;
            }
            // process attack
            if(target.t=='bacteria'){
              e.p=3;
              // default up
              let attack_shield=0;
              let defend_shield=1;
              if(y==1){ // down
                attack_shield=1;
                defend_shield=0;
              }
              if(x==-1){ // left
                attack_shield=2;
                defend_shield=3;
              }
              if(x==1){ // right
                attack_shield=3;
                defend_shield=2;
              }
              console.log('attack: ',attack_shield,defend_shield);
              e.s[attack_shield]-=1;
              if(e.s[attack_shield]<0){
                e.d=true;
              }
              target.s[defend_shield]-=1;
              if(target.s[defend_shield]<0){
                target.d=true;
              }
            }
          }
        }
      });
    }
    // Remove dead cells
    for(i=cells.length-1;i>=0;i--){
      if(cells[i].d){
        cells.splice(i,1) ;
      }
    }
    // redraw board
    draw_board();
  }

  function draw_board(){
    for(y=0;y<gsy;y++){
      for(x=0;x<gsx;x++){
        let cx=x+1;
        let cy=y+1;
        let cell=get_cell_at(cx,cy);
        if(cell){
          draw_cell(cell);
        }else{
          draw_empty(cx,cy);
        }
      }
    }
  }

  function draw_cell(cell){
    let dx=(cell.x-1)*spritesize;
    let dy=(cell.y-1)*spritesize;
    let shield='';
    if(cell.t=='wbc'||cell.t=='bacteria'){
      shield=`
        <div class="shield">
          <div class="up">${cell.s[0]}</div>
          <div class="down">${cell.s[1]}</div>
          <div class="left">${cell.s[2]}</div>
          <div class="right">${cell.s[3]}</div>
        </div>
      `;
    }
    $('#game').append(`<div class="cell ${cell.t}" style="top:${dy}px;left:${dx}px;">${shield}</div>`);
  }

  function draw_empty(x,y){
    let dx=(x-1)*spritesize;
    let dy=(y-1)*spritesize;
    $('#game').append(`<div class="cell empty" style="top:${dy}px;left:${dx}px;"></div>`);
  }

  function place_random(type){
    let added=false;
    let x,y,cell;
    while(!added){
      x=rint(1,gsx);
      y=rint(1,gsy);
      cell=get_cell_at(x,y);
      if(!cell){
        cell=gen_cell(type,x,y);
        cells.push(cell);
        added=true;
      }
    }
    return cell;
  }

  function gen_cell(type,x,y){
    let cell={
      t:type,
      x:x,
      y:y,
      s:[0,0,0,0],
      p:0, // processed state... (0=not processed,1=moved,2=cannot move,3=attacked)
      d:false // destroy
    }
    return cell;
  }

  function get_cell_at(x,y){
    let cell=false;
    cells.forEach((e)=>{
      if(e.x==x && e.y==y){
        cell=e;
        return;
      }
    });
    return cell;
  }

  function rint(min, max) {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

});
</script>

</body>
</html>