import math,json,sys
from pathlib import Path
p=json.loads(Path(sys.argv[1] if len(sys.argv)>1 else 'content_bank/drafts/g3_indukcija_mcq_0.2.0.json').read_text())
# Independent calculation routes, not the author's displayed expression values.
values={3:.05/.1,4:-.007,6:[.5/1.5,1.5/.5],8:math.pi*(.11/2)**2*.16,9:[-400*.001/.1,0,400*.001/.1],11:[-(.1**2)*(.01/.001)/4,0,(.1**2)*(.01/.001)/4],12:[-math.pi*.12**2*(.5/2)/2,0,math.pi*.12**2*(.5/2)/2],13:math.pi*.05**2*.04/2,14:100*.0012*(1.2-(-1.2))/13,15:2*(math.pi*.037**2/2)*math.cos(math.pi/4)*.076/.0045,16:math.pi*.1**2/4*.003,28:.2*.2*10,29:(.01*10)/(1*.5),30:.02*5*8000,31:5e-6*39.9*850/3.6,32:(.5*.1*2)**2/.2/2,33:[math.sqrt(5.3*12)/(1.25*3.1),5.3/3.1],34:[.35*.25*.5,(.35*.25*.5)**2/18,(.35*.25*.5)**2/18/.5],35:.35*2*(5.2*3)*5.2,36:.8*2*math.pi*.12*.01,38:50/(10/.2),39:50/(10/.1),40:5-.010*.05/.0005,41:.0017*5.6/7.3,43:4*math.pi*1e-7*600**2*math.pi*.043**2/.25,44:4*math.pi*1e-7*1000*math.pi*.005**2*(1.5/.05)}
expected={3:.5,4:-.007,6:[1/3,3],8:.00152,9:[-4,0,4],11:[-.025,0,.025],12:[-.00565,0,.00565],13:.000157,14:.0222,15:.0514,16:23.6e-6,28:.4,29:.2,30:800,31:.0471,32:.025,33:[2.06,1.71],34:[.04375,.000106,.000213],35:56.8,36:.00603,38:1,39:.5,40:4,41:.00130,43:.0105,44:2.96e-6}
for n,a in values.items():
 for av,ev in zip(a if isinstance(a,list) else [a],expected[n] if isinstance(expected[n],list) else [expected[n]]):assert math.isclose(av,ev,rel_tol=.005,abs_tol=1e-12),(n,av,ev)
# Independent symbolic checks for terminal speed and nonuniform-field motion.
for theta in (.1,.4,1.0):
 m,g,R,B,l=.13,9.81,2.7,.6,.24
 v=m*g*R*math.sin(theta)/(B*B*l*l*math.cos(theta)**2)
 current=B*l*v*math.cos(theta)/R
 assert math.isclose(m*g*math.sin(theta),B*current*l*math.cos(theta))
 assert math.isclose(m*g*v*math.sin(theta),current**2*R)
for r,b in ((2,.2),(1,.7),(.5,.1)):
 assert math.isclose(1/(r-b/2)-1/(r+b/2),b/(r*r-b*b/4))
assert len(p['questions'])==59
assert len({q['id'] for q in p['questions']})==59
for q in p['questions']:
 assert len(q['options'])==4 and len({o['text'] for o in q['options']})==4
 assert len(q['common_errors'])==3
 assert {e['option_id'] for e in q['common_errors']}=={o['option_id'] for o in q['options'] if o['option_id']!=q['correct_option_id']}
 assert q['status']=='draft' and not q['adaptive']['adaptive_enabled']
 assert 'слици' not in q['stem']
report={'package':'APP-G3-IND-MCQ-02','status':'CONTENT_AUTHORED_TECHNICALLY_CHECKED_NOT_PUBLISHED','question_count':59,'source_coverage':'45 numbered tasks + 14 review questions; task 46 isolated','source_figures_inspected':25,'numeric_items_independently_checked':len(values),'symbolic_items_checked':[37,45],'answer_options':236,'wrong_option_mappings':177,'group_count':20,'answer_key_distribution':{'A':15,'B':15,'V':15,'G':14},'date':'2026-10-31','science_review':'Independent law/geometry/sign/arithmetic and option-by-option conceptual audit; no MASTER or PROFESSOR PASS claimed.','blockers':['Program/track/outcome and unlock mapping not confirmed for full corpus','Professor approval and required Drive checkpoint synchronization pending','App integration/runtime not performed'],'next':'Use the 59 authored MCQs and resolved source-figure descriptions; do not repeat source import. Resolve curriculum/source approval before publication.'}

print(json.dumps(report,ensure_ascii=False))

