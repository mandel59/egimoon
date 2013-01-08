id = (...) -> ...
pack = (...) -> {...}
map = (f) -> (t) -> [f x for x in *t]
dup = map id
mapT = (f) -> (t) -> {k, f v for k, v in pairs t}
dupT = mapT id
head = (t) -> t[1]
tail = (t) ->
  with u = dup t
    table.remove u, 1
take = (t, i) ->
  u = {}
  v = dup t
  for j = 1, i
    u[j] = v[1]
    table.remove v, 1
  return u, v
puton = (t, k) ->
  with u = dupT t
    u[k] = 0 if type(u[k]) ~= 'number'
    u[k] += 1
pickup = (t, k) ->
  if type(t[k]) == 'number' and t[k] > 0
    with u = dupT t
      u[k] -= 1
append = (t, v) ->
  with u = dup t
    table.insert u, v
joinL = (t) ->
  with u = {}
    for v in *t
      for w in *v
        table.insert u, w
monad = (join, fmap) -> (m, k) ->
  join (fmap k) m
bind = monad joinL, map
seq = (a, b) ->
  with u = {}
    for i = a, b
      table.insert u, i
keys = (t) -> [k for k, _ in pairs t]

match_one = (env, value, datatype, pattern) ->
  datatype[head pattern] env, value, unpack tail pattern

match_all = (target, datatype, patterns) -> 
  for p, f in pairs patterns
    envM = match_one {}, target, datatype, p
    if #envM > 0 then return (map f) envM
  return {}

bindvar = (env, name, v) ->
  if name == nil then env
  else with e = dupT env
    e[name] = v

var = (name) -> { var, name }
val = (exp) -> { val, exp }
cons = (h, t) -> { cons, h, t }
join = (x, y) -> { join, x, y }
empty = -> { empty }

mkmultiset = (t) ->
  with u = {}
    for k in *t
      u[k] = 0 if u[k] == nil
      u[k] += 1

unmultiset = (m) ->
  with u = {}
    for k, v in pairs m
      for i = 1, v
        table.insert u, k

multiset_le = (a, b) ->
  for k, v in pairs a
    n = a[k] or 0
    m = b[k] or 0
    if not n <= m return false
  return true

multiset_eq = (a, b) ->
  multiset_le(a, b) and multiset_le(b, a)

List = (datatype) -> {
  [cons]: (env, v, hp, tp) ->
    if type(v) == 'table' and #v > 0
      bind (match_one env, (head v), datatype, hp), (env) ->
        match_one env, (tail v), (List datatype), tp
    else
      {}
  [join]: (env, v, xp, yp) ->
    if type(v) == 'table' and #v > 0
      bind (seq 0, #v), (i) ->
        xs, ys = take v, i
        bind (match_one env, xs, (List datatype), xp), (env) ->
          match_one env, ys, (List datatype), yp
    else
      {}
  [var]: (env, v, name) ->
    if type(v) == 'table'
      for i in *v
        if #match_one(env, i, datatype, var!) == 0
          return {}
      { bindvar env, name, v }
    else {}
  [val]: (env, v, exp) ->
    if type(v) == 'table' and v == exp(env)
      { env }
    else {}
  [empty]: (env, v) ->
    if type(v) == 'table' and #v == 0
      { env }
    else {}
}

Multiset = (datatype) -> {
  [cons]: (env, v, hp, tp) ->
    if type(v) == 'table'
      bind keys(v), (k) ->
        u = pickup v, k
        bind (match_one env, k, datatype, hp), (env) ->
          match_one env, u, (Multiset datatype), tp
    else
      {}
  [var]: (env, v, name) ->
    if type(v) == 'table'
      for k, _ in pairs v
        if #match_one(env, k, datatype, var!) == 0
          return {}
      { bindvar env, name, v }
    else {}
  [val]: (env, v, exp) ->
    if type(v) == 'table' and multiset_eq v, exp(env)
      { env }
    else {}
  [empty]: (env, v) ->
    if type(v) == 'table' and #(unmultiset v) == 0
      { env }
    else {}
}

Number = {
  [var]: (env, v, name) ->
    if type(v) == 'number'
      { bindvar env, name, v }
    else {}
  [val]: (env, v, exp) ->
    if type(v) == 'number' and v == exp(env)
      { env }
    else {}
}

{
  :List, :Multiset, :Number, :var, :val, :cons, :join, :match_all,
  :mkmultiset, :unmultiset, :empty
}
