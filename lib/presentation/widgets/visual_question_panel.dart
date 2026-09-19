import 'dart:math' as math;
import 'package:flutter/material.dart';

class VisualQuestionPanel extends StatelessWidget{
  const VisualQuestionPanel({super.key,required this.representation,required this.media});
  final String representation;final Map<String,dynamic> media;
  @override Widget build(BuildContext context){
    if(representation=='text'||media.isEmpty)return const SizedBox.shrink();
    final alt=(media['alt_text']??'Графички приказ уз задатак').toString();
    return Semantics(label:alt,child:Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      SizedBox(height:180,child:CustomPaint(painter:_PhysicsVisualPainter(representation,media))),
      const SizedBox(height:8),Text(alt,style:Theme.of(context).textTheme.bodySmall,textAlign:TextAlign.center)
    ]))));
  }
}
class _PhysicsVisualPainter extends CustomPainter{
  _PhysicsVisualPainter(this.type,this.m);final String type;final Map<String,dynamic> m;
  @override void paint(Canvas c,Size s){final p=Paint()..color=Colors.black87..strokeWidth=2..style=PaintingStyle.stroke;final axis=Paint()..color=Colors.black54..strokeWidth=1;
    c.drawLine(Offset(30,s.height-25),Offset(s.width-10,s.height-25),axis);c.drawLine(Offset(30,s.height-25),const Offset(30,10),axis);
    if(type=='graph'){final raw=m['points'];if(raw is List&&raw.length>=2){final pts=raw.map((e)=>(e as List).map((x)=>(x as num).toDouble()).toList()).toList();final mx=pts.map((e)=>e[0]).reduce(math.max),my=pts.map((e)=>e[1]).reduce(math.max);final path=Path();for(var i=0;i<pts.length;i++){final x=30+(s.width-45)*(mx==0?0:pts[i][0]/mx),y=s.height-25-(s.height-40)*(my==0?0:pts[i][1]/my);if(i==0)path.moveTo(x,y);else path.lineTo(x,y);}c.drawPath(path,p);return;}final seg=m['segments'];if(seg is List&&seg.isNotEmpty){final n=seg.length;for(var i=0;i<n;i++){final v=((seg[i] as Map)['v']??(seg[i] as Map)['speed_kmh']??20) as num;final y=s.height-25-math.min(s.height-45,v.toDouble());final x0=30+i*(s.width-45)/n,x1=30+(i+1)*(s.width-45)/n;c.drawLine(Offset(x0,y),Offset(x1,y),p);}return;}}
    final vectors=m['vectors'];if(vectors is List&&vectors.isNotEmpty){var x=40.0,y=s.height-35;for(final v in vectors){if(v is List&&v.length>=2){final nx=x+(v[0] as num).toDouble()*10,ny=y-(v[1] as num).toDouble()*10;c.drawLine(Offset(x,y),Offset(nx,ny),p);c.drawCircle(Offset(nx,ny),3,p);x=nx;y=ny;}}return;}
    if(vectors is Map){final center=Offset(s.width/2,s.height/2);var k=0;for(final v in vectors.values){if(v is List&&v.length>=2){final end=Offset(center.dx+(v[0] as num).toDouble()*12,center.dy-(v[1] as num).toDouble()*12);c.drawLine(center,end,p);c.drawCircle(end,3,p);k++;}}if(k>0)return;}
    c.drawRect(Rect.fromLTWH(45,35,s.width-90,s.height-75),p);
  }
  @override bool shouldRepaint(covariant _PhysicsVisualPainter old)=>old.type!=type||old.m!=m;
}
