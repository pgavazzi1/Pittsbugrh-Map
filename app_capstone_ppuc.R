# install.packages("shiny")
# install.packages("leaflet")
#install.packages("tidyverse")
# install.packages("rgdal")
# install.packages("maptools")
#install.packages("sp")


library("shinythemes")
library(leaflet)
library(tidyverse)
library(shiny)
library(dplyr)

#Notes
#make sure shapefile and contract data is in the same myapp/ folder

is_even<-function(x){
  if(x%%2 == 0){
    return(TRUE)
  }else{
    return(FALSE)
  }
}


data_police<-read.csv("contract data for r visualization - Sheet1.csv")
muni_sf<-rgdal::readOGR("Allegheny_County_Municipal_Boundaries-shp/LandRecords_LANDRECORDS_OWNER_Municipalities.shp")

muni_sf<- spTransform(muni_sf, CRS("+proj=longlat +datum=WGS84"))

count_split<-str_split(data_police$Keywords.found.in.contract, "," )

#Going to color based on keyword, figuring str_split, transparency based on keywords
#Implement this before Friday 8/27
#Total number, full time, 
#Mouseover show the name of the police department
#Bill of Rights
count_prob_phrases<-unique(unlist(count_split))

# data_police$Keywords.found.in.contract<-replace_na(data = data_police$Keywords.found.in.contract, "none")
m<-merge(muni_sf, data_police, by.x = "LABEL", by.y = "Location.Name")
names(m)



popup = paste(sep = "<br/>","<b>" , m$LABEL,
              paste0("<a href='"
                     , m$Link.to.police.department
                     , "' target='_blank'>"
                     , "Link to police department website</a>"), 
              paste0("Total number of Full Time Police Officers as of 2019: ", m$Total.Number.Police.Officers..as.of.2019.),
              paste0("Police Bill of Rights?: ", m$Do.they.use.a.police.bill.of.rights.),"<b>",
              paste0("Problematic phrases in police union contracts: ", m$Keywords.found.in.contract),"</b>")




num_regions<-unique(m$REGION)

num_COG<-unique(m$COG)
num_SD<-unique(m$SCHOOLD)
color_pal_COG<-colorFactor(topo.colors(length(num_COG)), m$COG)
color_pal_REGION<-colorFactor(topo.colors(length(num_regions)), m$REGION)
color_pal_SD<-colorFactor(topo.colors(length(num_SD)), m$SCHOOLD)




ui<-fluidPage(
  theme = shinytheme("flatly"),
  
  
  p(),
  titlePanel("Allegheny County Municipal Map: Police Contracts"), #established title panel
  sidebarLayout(
    
    sidebarPanel(
      helpText("As a part of the Allegheny County Policing Project (ACPP), this tool allows users to learn more about the policing practices and procedures of various municipalities
               through an interactive map"),
      selectInput("colorcode", label = "Choose from these options",
                  choices = c("Region", "Council of Governments (COG)" = "COG",
                              "School District"),
                  selected = "COG"
      )
      
      
    ), mainPanel(
      
      leafletOutput("mymap"), radioButtons("prob_phrases", label = h3("Phrase found in contract"), 
                                           choices = c("time limit", "subpoena", "false arrest", "discipline", "destroy", "release")),
      actionButton("action", label = "Reset")
      
      
    )
  ) 
)



server <- function(input, output, session){
  
  
  
  
  
  output$mymap <- renderLeaflet({
    leaflet()%>% addTiles()%>%
      addPolygons(data = m, label= m$LABEL, color = "#444444", weight = 1, smoothFactor = 0.5,
                  opacity = 1.0, fillOpacity = 0.5,
                  fillColor ="orange",
                  highlightOptions = highlightOptions(color = "red", weight = 2,
                                                      bringToFront = TRUE))
    
    
    
  })
  
  
  
  observe({
    proxy <- leafletProxy("mymap", data = m)
    req(input$prob_phrases)
    if(input$prob_phrases %in% "time limit"){
      #get the selected polygon and extract the label point 
      selected_polygon <- subset(m, str_detect(unlist(m$Keywords.found.in.contract), "time limit"))
      polygon_labelPt <- selected_polygon@polygons[[1]]@labpt
      
      #remove any previously highlighted polygon
      proxy %>% clearGroup("highlighted_polygon")
      
      #center the view on the polygon 
      #proxy %>% setView(lng=polygon_labelPt[1],lat=polygon_labelPt[2],zoom=7)
      
      not_selected <-subset(m, !str_detect(unlist(m$Keywords.found.in.contract), "time limit") | is.na(unlist(m$Keywords.found.in.contract)))
      
      #add a slightly thicker red polygon on top of the selected one
      proxy %>% addPolylines(stroke=TRUE, weight = 5,color="red",data=selected_polygon,group="highlighted_polygon")
      
      
    }else if(input$prob_phrases %in% "subpoena"){
      #get the selected polygon and extract the label point
      selected_polygon <- subset(m, str_detect(unlist(m$Keywords.found.in.contract), "subpoena"))
      polygon_labelPt <- selected_polygon@polygons[[1]]@labpt
      
      #remove any previously highlighted polygon
      proxy %>% clearGroup("highlighted_polygon")
      
      #center the view on the polygon
      #proxy %>% setView(lng=polygon_labelPt[1],lat=polygon_labelPt[2],zoom=7)
      not_selected <-subset(m, !str_detect(unlist(m$Keywords.found.in.contract), "subpoena")| is.na(unlist(m$Keywords.found.in.contract)))
      #add a slightly thicker red polygon on top of the selected one
      proxy %>% addPolylines(stroke=TRUE, weight = 5,color="red",data=selected_polygon,group="highlighted_polygon")
      
      
    }else if(input$prob_phrases %in% "release"){
      #get the selected polygon and extract the label point
      selected_polygon <- subset(m, str_detect(unlist(m$Keywords.found.in.contract), "release"))
      polygon_labelPt <- selected_polygon@polygons[[1]]@labpt
      
      #remove any previously highlighted polygon
      proxy %>% clearGroup("highlighted_polygon")
      
      #center the view on the polygon
      #proxy %>% setView(lng=polygon_labelPt[1],lat=polygon_labelPt[2],zoom=7)
      not_selected <-subset(m, !str_detect(unlist(m$Keywords.found.in.contract), "release")| is.na(unlist(m$Keywords.found.in.contract)))
      #add a slightly thicker red polygon on top of the selected one
      proxy %>% addPolylines(stroke=TRUE, weight = 5,color="red",data=selected_polygon,group="highlighted_polygon")
      
      
    }else if(input$prob_phrases %in% "discipline"){
      #get the selected polygon and extract the label point
      selected_polygon <- subset(m,str_detect(unlist(m$Keywords.found.in.contract), "discipline"))
      polygon_labelPt <- selected_polygon@polygons[[1]]@labpt
      
      
      #remove any previously highlighted polygon
      proxy %>% clearGroup("highlighted_polygon")
      
      #center the view on the polygon
      #proxy %>% setView(lng=polygon_labelPt[1],lat=polygon_labelPt[2],zoom=7)
      not_selected <-subset(m, !str_detect(unlist(m$Keywords.found.in.contract), "discipline")| is.na(unlist(m$Keywords.found.in.contract)))
      #add a slightly thicker red polygon on top of the selected one
      proxy %>% addPolylines(stroke=TRUE, weight = 5,color="red",data=selected_polygon,group="highlighted_polygon")
      
      
    }else if(input$prob_phrases %in% "false arrest"){
      #get the selected polygon and extract the label point
      selected_polygon <- subset(m,str_detect(unlist(m$Keywords.found.in.contract), "false arrest"))
      polygon_labelPt <- selected_polygon@polygons[[1]]@labpt
      
      #remove any previously highlighted polygon
      proxy %>% clearGroup("highlighted_polygon")
      
      #center the view on the polygon
      #proxy %>% setView(lng=polygon_labelPt[1],lat=polygon_labelPt[2],zoom=7)
      not_selected <-subset(m, !str_detect(unlist(m$Keywords.found.in.contract), "false arrest")| is.na(unlist(m$Keywords.found.in.contract)))
      #add a slightly thicker red polygon on top of the selected one
      
      proxy %>% addPolylines(stroke=TRUE, weight = 5,color="red",data=selected_polygon,group="highlighted_polygon")
      
      
      
      
    }else if(input$prob_phrases %in% "destroy"){
      #get the selected polygon and extract the label point
      selected_polygon <- subset(m,str_detect(unlist(m$Keywords.found.in.contract), "destroy"))
      polygon_labelPt <- selected_polygon@polygons[[1]]@labpt
      
      #remove any previously highlighted polygon
      proxy %>% clearGroup("highlighted_polygon")
      
      #center the view on the polygon
      #proxy %>% setView(lng=polygon_labelPt[1],lat=polygon_labelPt[2],zoom=7)
      not_selected <-subset(m, !str_detect(unlist(m$Keywords.found.in.contract), "destroy")| is.na(unlist(m$Keywords.found.in.contract)))
      #add a slightly thicker red polygon on top of the selected one
      
      proxy %>% addPolylines(stroke=TRUE, weight = 5,color="red",data=selected_polygon,group="highlighted_polygon")
      
    }
    
    
    
    
    
  })
  
  
  observe({
    
    req(input$colorcode)
    test<-reactiveVal()
    
    if(input$colorcode %in% "COG"){
      test = "COG"
      
    }else if(input$colorcode %in% "Region"){
      test = "REGION"
    }else{
      test = "SCHOOLD"
    }
    req(test)
    ind<-which(names(m) == test)
    req(ind)
    
    
    if(ind == 9){
      leafletProxy("mymap", data = m ) %>%
        clearTiles()%>% 
        addPolygons(data = m,
                    label= m$LABEL, # hovering will reveal municipality name
                    color = "black", # border color
                    fillColor = ~color_pal_REGION(REGION),
                    weight = 1.0, # border thickness
                    opacity = 1.0, # border transparency
                    fillOpacity = 0.8, 
                    popup= popup,
                    highlightOptions = highlightOptions(color = "red", weight = 2,
                                                        bringToFront = FALSE), group = "REGION")
      
      
    }else if(ind ==5){
      leafletProxy("mymap", data = m ) %>%
        clearTiles()%>% 
        addPolygons(data = m,
                    label= m$LABEL, # hovering will reveal municipality name
                    color = "black", # border color
                    fillColor =~color_pal_COG(COG),
                    weight = 1.0, # border thickness
                    opacity = 1.0, # border transparency
                    fillOpacity = 0.8, 
                    popup= popup,
                    highlightOptions = highlightOptions(color = "red", weight = 2,
                                                        bringToFront = FALSE), group = "COG")
      
      
      
      
    }else if(ind == 6){
      leafletProxy("mymap", data = m ) %>%
        clearTiles()%>% 
        addPolygons(data = m,
                    label= m$LABEL, # hovering will reveal municipality name
                    color = "black", # border color
                    fillColor = ~color_pal_SD(SCHOOLD),  
                    weight = 1.0, # border thickness
                    opacity = 1.0, # border transparency
                    fillOpacity = 0.8, 
                    popup= popup,
                    highlightOptions = highlightOptions(color = "red", weight = 2,
                                                        bringToFront = FALSE), group = "SCHOOLD")
      
      
      
      
    }else{
      leafletProxy("mymap", data = m)%>% clearTiles()%>%
        addPolygons(data = m, label= m$LABEL, color = "black", weight = 1, smoothFactor = 0.5,
                    opacity = 1.0, fillOpacity = 0.5,
                    fillColor ="#C0C0C0",
                    highlightOptions = highlightOptions(color = "red", weight = 2,
                                                        bringToFront = FALSE))
      
    }
    if(input$colorcode %in% "COG"){
      testlegend = "COG"
      
    }else if(input$colorcode %in% "Region"){
      testlegend = "REGION"
    }else{
      testlegend = "SCHOOLD"
    }
    req(testlegend)
    indlegend<-which(names(m) == testlegend)
    req(indlegend)
    
    #pal<-color_pal_COG(m$COG)
    #data_value<-m$COG
    if (indlegend== 5) {
      data_value<-m$COG
      num<-num_COG
    }else if (indlegend==6){
      data_value<-m$SCHOOLD
      num<-num_SD
    }else if(indlegend ==9){
      data_value<-m$REGION
      num<-num_regions
    }
    req(data_value)
    req(num)
    leafletProxy("mymap", data = m) %>% 
      clearControls()%>%
      addLegend("topright",
                pal = colorFactor(topo.colors(length(num)), data_value), values = ~data_value, labels = ~data_value, title = paste0("Legend: ", names(m[indlegend])), layerId = "legend" )
    req(input$action)
    if(is_even(input$action)){
      leafletProxy("mymap", data = m) %>% clearGroup("highlighted_polygon")
    }  
  })
  
  
  
  
  
  
  
  
}




# Run app ----
shinyApp(ui, server )