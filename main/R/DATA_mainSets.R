# NOTE: subsets are done when mapping


#' n = NESTS()
NESTS <- function() {
  # last state
  n = DBq('SELECT nest_id, species, max(CONCAT_WS(" ",date,time_visit)) datetime_, nest_state
                        FROM NESTS
                          GROUP BY species, nest_id, nest_state')

  setorder(n, nest_id)
  n[, lastd := max(datetime_), by = .(nest_id)]
  n = n[datetime_ == lastd][, lastd := NULL]
  n[, lastCheck := difftime(Sys.time(), datetime_, units = "days") |> as.numeric() |> round(1)]

  # lat, lon for F state, species
  g = DBq('SELECT n.gps_id, n.gps_point, CONCAT_WS(" ",n.date,n.time_visit) datetime_found, n.nest_id, lat, lon
                  FROM NESTS n JOIN GPS_POINTS g on n.gps_id = g.gps_id AND n.gps_point = g.gps_point
                    WHERE n.gps_id is not NULL and n.nest_state = "F"')
  g[, datetime_ := as.POSIXct(datetime_found)]

  g = g[, .(lat = mean(lat), lon = mean(lon), datetime_found = min(datetime_found)), .(nest_id)]

  n = merge(n, g, by = "nest_id", all.x = TRUE)
  n[, datetime_found := as.POSIXct(datetime_found)]
  n[, firstCheck := difftime(Sys.time(), datetime_found, units = "days") |> as.numeric() |> round(1)]

  # clutch size
  cs = DBq("SELECT  nest_id, min(clutch_size) iniClutch, max(clutch_size) clutch FROM NESTS GROUP BY nest_id")

  # collected
  e = DBq("select distinct nest_id from NESTS where nest_state = 'C' ")
  e[, collected := 1]

  # days till hatching
  dth = DBq("SELECT * FROM EGGS")
  h = hatching_table() # TODO
  dth = merge(dth, h, by = c("float_angle", "float_surface"))
  dth[, est_hatch_date := date + days_till_hatching]
  dth[, days_till_hatching := difftime(est_hatch_date, Sys.time(), units = "days") |> as.numeric() |> round(1)]
  dth = dth[, .(est_hatch_date = min(est_hatch_date), days_till_hatching = min(days_till_hatching)), by = nest_id]
  

  # male, female confirmed identity
  id = DBq("SELECT distinct n.nest_id, c.ring , c.field_sex sex
                from NESTS n
                 left join CAPTURES c on c.nest_id = n.nest_id
                   where c.ring is not NULL")
  id = dcast(id, nest_id ~ sex, value.var = "ring")

  # prepare final set
  setnames(n, "nest_state", "last_state")
  
  o = merge(n, cs,  by = "nest_id", all.x = TRUE)
  o = merge(o, e,   by = "nest_id", all.x = TRUE)
  o[is.na(collected), collected := 0]
  o = merge(o, dth, by = "nest_id", all.x = TRUE)
  o = merge(o, id,  by = "nest_id", all.x = TRUE)

  o
}

#' ns = subsetNESTS(NESTS(), state = input$nest_state, sp = input$nest_species, d2h = input$days_to_hatch)
#' Keep the subset separated from NESTS() so that N() is loaded only once. Subset is done through input$
subsetNESTS <- function(n, state, sp, d2h) {
  
  n = n[!is.na(lat)]
  
  # subsets
  if (!missing(state) | !is.null(state)) {
    n= n[last_state %in% state]
  }

  if (!missing(sp) | !is.null(sp)) {
    n= n[species %in% sp]
  }

  if (!missing(d2h) | !is.null(d2h)) {
    n = n[days_till_hatching <= d2h | is.na(days_till_hatching)]
  }
  
  n

}