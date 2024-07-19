
dfsys <- function() {

  x = fread("df -H  --type ext4", fill = TRUE)
  x[, `Use%` := str_remove(`Use%`, "%") |> as.numeric()]
  x[,.(Avail, `Use%`)]

}

dfsys_output <- function( x = dfsys() ) {
  
  state = fcase(x$`Use%` < 60, "success", x$`Use%` %between% c(60, 70), "warming", x$`Use%` > 70, "danger")
  
    
  o1 = glue('
  <a>
  <span class="badge badge-pill badge-primary">
  {x$Avail} free
  </span>
  </a>
  ')

  
  o2 = glue('
  <a>
  <span class="badge badge-pill badge-{state}">
  {x$`Use%`}% used.
   </span>
   </a>
   ')

  o = glue('
   <div> {o1} {o2} </div>
   ')


  HTML(o)



}

# install app locally as a shiny server App 
appInst <- function(app = app_nam){

  to = paste0('/srv/shiny-server/', app_nam)

  if (fs::dir_exists(to)) {
    fs::dir_delete(to)
  }

  fs::dir_copy(getwd(), to)

}