#!/usr/bin/env python3
"""Independent stdlib oracle. Enumeration, rather than the production binary search.
Fixtures are deterministic and generated separately from reference expectations.
Run from the repository root: python tools/oracle.py --target wasm-gc.
"""
import argparse, json, math, pathlib, random, subprocess, sys, struct
ROOT = pathlib.Path(__file__).resolve().parents[1]

def adjacent(value, direction):
    bits = struct.unpack('>Q', struct.pack('>d', value))[0]
    return struct.unpack('>d', struct.pack('>Q', bits+direction))[0]

def cases():
    rng = random.Random(61109)
    result = []
    for n in range(1, 33):
        values = [float(rng.randrange(-5, 10)) for _ in range(n)]
        for alpha in [0.01, 0.1, 0.2, 0.5, 0.9, 1.0/(n+1), n/(n+1)]:
            result.append((values, alpha))
        boundary = (max(1, n//2))/(n+1)
        result.extend((values, a) for a in [adjacent(boundary,-1),boundary,adjacent(boundary,1)])
    return result

def reference(values, alpha):
    n = len(values)
    # Enumerate every possible conservative p-value on the finite grid.
    admissible = [k for k in range(n+1) if k/(n+1) <= alpha]
    rank = n+1-max(admissible)
    threshold = sorted(values)[rank-1] if rank <= n else "+inf"
    p_values = [(1+sum(x >= candidate for x in values))/(n+1) for candidate in [-6.0,0.0,4.0,10.0]]
    return [rank,threshold,p_values]

def class_reference(row, rule):
    if rule == 0:
        return [1-p for p in row]
    # Pairwise precedence defines APS independently of the production sorting loop.
    scores = []
    for label,p in enumerate(row):
        before = [j for j,q in enumerate(row) if q > p or (q == p and j < label)]
        score = sum(row[j] for j in before)+p
        if rule == 2:
            score += 0.1*max(len(before)+1-1,0)
        scores.append(score)
    return scores

def generate():
    inputs = cases()
    fixture = '///| Generated input fixtures only; expectations live in Python.\nfn oracle_cases() -> Array[(Array[Double], Double)] {\n  [\n'
    fixture += ',\n'.join('    ('+json.dumps(v)+', '+repr(a)+')' for v,a in inputs)
    fixture += '\n  ]\n}\n'
    (ROOT/'examples/oracle/cases.mbt').write_text(fixture, encoding='utf-8')

def close(a,b,path='root'):
    if isinstance(b,list):
        if not isinstance(a,list) or len(a)!=len(b): raise AssertionError(path+': shape mismatch')
        for i,(x,y) in enumerate(zip(a,b)): close(x,y,path+'['+str(i)+']')
    elif isinstance(b,(int,float)):
        if not isinstance(a,(int,float)) or not math.isclose(a,b,rel_tol=1e-12,abs_tol=1e-12): raise AssertionError(path+': '+repr(a)+' != '+repr(b))
    elif a != b: raise AssertionError(path+': '+repr(a)+' != '+repr(b))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--target',default='wasm-gc')
    parser.add_argument('--moon',default='moon')
    parser.add_argument('--generate',action='store_true')
    args=parser.parse_args()
    if args.generate: generate(); return
    process=subprocess.run([args.moon,'run','--deny-warn','--target',args.target,'examples/oracle'],cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    if process.returncode:
        print(process.stdout+process.stderr,file=sys.stderr);sys.exit(process.returncode)
    actual=json.loads(process.stdout)
    expected=[reference(*item) for item in cases()]
    classes=[class_reference(row,rule) for row in [[0.8,0.1,0.1],[0.5,0.5,0.0],[0.25,0.25,0.25,0.25],[0.0,0.0,1.0]] for rule in range(3)]
    expected.extend(classes)
    # Signed CQR, scaled residuals, CV+ alignment and multi-output maximum scores.
    expected.extend([[-2.0,-1.0,1.0,2.0],[1.0,2.0,3.0,4.0],[7.0,24.0],[6.0,14.0,12.0,28.0]])
    close(actual,expected)
    print(json.dumps({'target':args.target,'cases':len(expected),'status':'PASS','rank_cases':len(cases()),'classification_cases':len(classes)},sort_keys=True))

if __name__=='__main__':main()
