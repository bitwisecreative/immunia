$(function(){

    debug=false;
    controls=true;
  
    // grid
    gsx=4;
    gsy=4;
    spritesize=128;
    cells=[];
    maxdepth=13; // levelgen
    win_moves_run_limit=Math.pow(4,maxdepth);
    win_moves_runs=0;
  
    // mode
    mode='#random_play';
    hash=location.hash;
    if(hash) mode=hash;
    console.log(mode);
  
    if(mode=='#random_play'){
      gen_random_board();
      draw_board();
    }
  
    if(mode=='#levelgen_single'||mode=='#levelgen'){
      gen_random_board();
      let state=state_string();
      win_moves=[];
      gen_win_moves(state,'');
      console.log(state,win_moves);
      if(win_moves.length>0){
        $.post('./',{state:state,win_moves:JSON.stringify(win_moves)}).done(function(){
          if(mode=='#levelgen'){
            setTimeout(function(){
                location.reload();
            },100);  
          }
        });
      }else{
        if(mode=='#levelgen'){
          setTimeout(function(){
              location.reload();
          },100);  
        }
      }
    }

    if(mode=='#play_and_rate'){
      $.get('./?rate=1').done(function(d){
        if(typeof d=='string'){
          d=JSON.parse(d);
        }
        console.log(d);
        $('#rate-rowid').text('Rating ROWID: '+d.rowid);
        $('#statestring').val(d.state);
        let options='<option disabled selected></option>';
        for(let i=0;i<11;i++){
          options+=`
            <option value="${i}">${i}</option>
          `;
        }
        let rateSendSelect=`
          <select id="rate-send">
            ${options}
          </select>
        `;
        $('#rate-send').html(rateSendSelect);
        $(document).on('change','#rate-send select',function(){
          $.post('./',{rowid:d.rowid,rating:$(this).val()});
        });
        state_string($('#statestring').val());
        draw_board();
      });
    }
  
    //
    // EVENTS
    //
    $(document).on('keyup',function(e){
      if(controls){
        switch(e.key){
          case 'ArrowUp':
            move(0,-1);
            draw_board();
            break;
          case 'ArrowDown':
            move(0,1);
            draw_board();
            break;
          case 'ArrowLeft':
            move(-1,0);
            draw_board();
            break;
          case 'ArrowRight':
            move(1,0);
            draw_board();
            break;
        }
      }
    });
    $('a').on('click',function(){
      setTimeout(function(){
        location.reload();
      },100);    
    });
    $('#load').on('click',function(){
      state_string($('#statestring').val());
      draw_board();
    });
    // Level Editor
    $(document).on('click','.cell',function(){
      $('.cell').removeClass('active');
      $(this).addClass('active');
      let x=$(this).data('x');
      let y=$(this).data('y');
      $('#edit-loc').text(x+','+y);
      let cell=get_cell_at(x,y);
      if(!cell){
        $('.select-empty input').prop('checked',true);
        $('.edit-shields input').val('');
      }else{
        if(cell.t=='blocked'){
          $('.select-blocked input').prop('checked',true);
          $('.edit-shields input').val('');
        }
        if(cell.t=='wbc'||cell.t=='bacteria'){
          if(cell.t=='wbc'){
            $('.select-wbc input').prop('checked',true);
          }else{
            $('.select-bacteria input').prop('checked',true);
          }
          $('#edit-up-shield').val(cell.s[0]);
          $('#edit-down-shield').val(cell.s[1]);
          $('#edit-left-shield').val(cell.s[2]);
          $('#edit-right-shield').val(cell.s[3]);
        }
      }
    });
    function getEditLoc(){
      let loc=$('#edit-loc').text();
      if(!loc){
        return false;
      }
      loc=loc.split(',');
      let x=loc[0];
      let y=loc[1];
      return [x,y];
    }
    $('input[name="edit-type"]').on('change',function(){
      let loc=getEditLoc();
      if(!loc) return;
      let x=loc[0];
      let y=loc[1];
      let type=$(this).val();
      let cell_index=get_cell_index_at(x,y);
      if(type=='empty'){
        if(cell_index){
          cells.splice(cell_index,1);
        }
      }else{
        let new_cell=gen_cell(type,x,y);
        if(type=='wbc'){
          $('.edit-shields input').val(0);
        }
        if(type=='bacteria'){
          new_cell.s=[3,3,3,3];
          $('.edit-shields input').val(3);
        }
        if(!cell_index){
          cells.push(new_cell);
        }else{
          cells[cell_index]=new_cell;
        }
      }
      draw_board();
    });
    $('.edit-shields input').on('change',function(){
      let loc=getEditLoc();
      if(!loc) return;
      let x=loc[0];
      let y=loc[1];
      let cell=get_cell_at(x,y);
      if(!cell){
        return false;
      }
      if(cell.t=='blocked'){
        return false;
      }
      let id=$(this).attr('id');
      let val=$(this).val();
      let m={
        'edit-up-shield':0,
        'edit-down-shield':1,
        'edit-left-shield':2,
        'edit-right-shield':3,
      };
      cell.s[m[id]]=val;
      //
      draw_board();
    });
  
    //
    // FUNCTIONS
    //
  
    function gen_win_moves(ss,seq){
      // Just want the first win moves
      if(win_moves.length>0){
        return;
      }
      // counter and limiter
      win_moves_runs++;
      if(win_moves_runs%100000===0){
        console.log(win_moves_runs);
      }
      if(win_moves_runs>win_moves_run_limit){
        return;
      }
      // max depth
      if(seq.length>=maxdepth){
        return;
      }
      // test each move dir for game states
      let moves=[
        [1,0,-1],
        [2,0,1],
        [3,-1,0],
        [4,1,0]
      ];
      // randomize order...
      shuffle(moves);
      // check the moves
      for(let i=0;i<moves.length;i++){
        // set state
        state_string(ss);
        let moveid=moves[i][0].toString();
        move(moves[i][1],moves[i][2]);
        // sequence after move
        let nseq=seq+moveid;
        // win?
        if(count_cells_by_type('bacteria')==0){
          // push to external win_moves array
          win_moves.push(nseq);
        }else{
          // keep going?
          if(count_cells_by_type('wbc')>0){
            gen_win_moves(state_string(),nseq);
          }
        }
      }
    }
  
    function count_cells_by_type(type){
      let c=0;
      cells.forEach((e)=>{
        if(e.t==type){
          c++;
        }
      });
      return c;
    }
  
    // build state from string, or return current state as string
    function state_string(str){
      if(str){
        if(debug) console.log(str);
        let a=str.split(',');
        if(a.length!=gsx*gsy){
          throw new Error('State string: invalid length.');
        }
        cells=[];
        let tok=['e','x','w','b'];
        for(let i=0;i<a.length;i++){
          let x=(i%gsx)+1;
          let y=(Math.floor(i/gsy))+1;
          if(debug) console.log(x,y);
          let t=a[i].substring(0,1);
          if(debug) console.log(t);
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
        if(debug) console.log(outstr);
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
      // wbc 0 or 1 shields... chance to set random
      // bacteria 2 or 3 shields... chance to remove random
      cells.forEach((e)=>{
        if(e.t=='wbc'){
          e.s=[rint(0,1),rint(0,1),rint(0,1),rint(0,1)];
        }
        if(e.t=='bacteria'){
          e.s=[rint(2,3),rint(2,3),rint(2,3),rint(2,3)];
        }
        for(i=0;i<4;i++){
          if(rint(1,3)==1){
            e.s[i]=rint(0,3);
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
      if(debug) console.log('move: '+x+','+y);
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
      // check full row and force move
      function check_row(cell){
        let r=[];
        // check y
        if(x==0){
          r=[[cell.x,1],[cell.x,2],[cell.x,3],[cell.x,4]];
        }
        // check x
        if(y==0){
          r=[[1,cell.y],[2,cell.y],[3,cell.y],[4,cell.y]];
        }
        // if all wbcs, then need to move them all...
        let wbcs=[];
        for(let i=0;i<r.length;i++){
          let c=get_cell_at(r[i][0],r[i][1]);
          if(c && c.t=='wbc'){
            wbcs.push(c);
          }
        }
        if(wbcs.length==4){
          if(debug) console.log(r,wbcs);
          // up or left
          if(x<0||y<0){
            let tmp=[wbcs[3].x,wbcs[3].y];
            for(let i=wbcs.length-1;i>=0;i--){
              wbcs[i].p=1; // moved...
              if(i==0){
                wbcs[i].x=tmp[0];
                wbcs[i].y=tmp[1];
              }else{
                wbcs[i].x=wbcs[i-1].x;
                wbcs[i].y=wbcs[i-1].y;
              }
            }
          // down or right
          }else{
            let tmp=[wbcs[0].x,wbcs[0].y];
            for(let i=0;i<wbcs.length;i++){
              wbcs[i].p=1; // moved...
              if(i==3){
                wbcs[i].x=tmp[0];
                wbcs[i].y=tmp[1];
              }else{
                wbcs[i].x=wbcs[i+1].x;
                wbcs[i].y=wbcs[i+1].y;
              }
            }
          }
        }
      }
      // move
      let limiter=0;
      while(!all_wbcs_move_processed()){
        limiter++;
        if(limiter>100){
          throw new Error('move limiter');
          cells.forEach((e)=>{
            e.p=4; // fubard
          });
        }
        cells.forEach((e)=>{
          if(e.t=='wbc' && e.p==0){
            if(debug) console.log(e.x,e.y,e.x+x,e.y+y,gridloop(e.x+x,e.y+y));
            let tloc=gridloop(e.x+x,e.y+y);
            let tx=tloc[0];
            let ty=tloc[1];
            let target=get_cell_at(tx,ty);
            if(!target){
              e.p=1;
              e.x=tx;
              e.y=ty;
            }else{
              // just blocked
              if(target.t=='blocked'){
                e.p=2;
              }
              // wbc handling...
              if(target.t=='wbc'){
                // blocked by wbc
                if(target.p>0){
                  e.p=2;
                }else{
                  // check and force move full rows of wbc to avoid inf loop
                  check_row(e);
                }
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
                if(debug) console.log('attack: ',attack_shield,defend_shield);
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
      let ss=state_string();
      $('#playstring').val(ss);
    }
  
    function draw_cell(cell){
      let dx=(cell.x-1)*spritesize;
      let dy=(cell.y-1)*spritesize;
      let shield='';
      function draw_shield(n){
        let s='';
        for(let i=0;i<n;i++){
          s+='█';
        }
        return s;
      }
      if(cell.t=='wbc'||cell.t=='bacteria'){
        shield=`
          <div class="shield">
            <div class="up">${draw_shield(cell.s[0])}</div>
            <div class="down">${draw_shield(cell.s[1])}</div>
            <div class="left">${draw_shield(cell.s[2])}</div>
            <div class="right">${draw_shield(cell.s[3])}</div>
          </div>
        `;
      }
      $('#game').append(`<div class="cell ${cell.t}" data-x="${cell.x}" data-y="${cell.y}" style="top:${dy}px;left:${dx}px;">${shield}</div>`);
    }
  
    function draw_empty(x,y){
      let dx=(x-1)*spritesize;
      let dy=(y-1)*spritesize;
      $('#game').append(`<div class="cell empty" data-x="${x}" data-y="${y}" style="top:${dy}px;left:${dx}px;"></div>`);
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

    function get_cell_index_at(x,y){
      for(let i=0;i<cells.length;i++){
        if(cells[i].x==x && cells[i].y==y){
          return i;
        }
      }
      return false;
    }
  
    function rint(min, max) {
      min = Math.ceil(min);
      max = Math.floor(max);
      return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    function shuffle(array) {
      let currentIndex = array.length,  randomIndex;
      while (currentIndex > 0) {
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex--;
        [array[currentIndex], array[randomIndex]] = [array[randomIndex], array[currentIndex]];
      }
      return array;
    }
    
  
  });