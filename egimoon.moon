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
pickup = (t, i) ->
  u = dup t
  table.remove u, i
  return t[i], u
append = (t, v) ->
  with u = dup t
    table.insert u, v
join = (t) ->
  with u = {}
    for v in *t
      for w in *v
        table.insert u, w
monad = (join, fmap) -> (m, k) ->
  join (fmap k) m
bind = monad join, map

show = (d) ->
  if type(d) == 'table'
    if #d > 0
      "{#{table.concat ((map show) d), ','}}"
    else
      u = {}
      for k, v in pairs d
        table.insert u, "#{k}:#{show v}"
      "{#{table.concat u, ','}}"
  else
    tostring(d)

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
cons = (h, t) -> { cons, h, t }

List = (datatype) -> {
  [cons]: (env, v, hp, tp) ->
    if type(v) == 'table' and #v > 0
      bind (match_one env, (head v), datatype, hp), (env) ->
        match_one env, (tail v), (List datatype), tp
    else
      {}
  [var]: (env, v, name) ->
    if type(v) == 'table'
      for i in *v
        if #match_one(env, i, datatype, var!) == 0
          return {}
      { bindvar env, name, v }
    else {}
}

Number = {
  [var]: (env, v, name) ->
    if type(v) == 'number'
      { bindvar env, name, v }
    else {}
}

print show match_all {1, 2, 3}, (List Number),
  [cons var('x'), var('ts')]: => {@x, @ts}
