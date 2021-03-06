# ChannelAttribution: Markov model for online multi-channel attribution
# Copyright (C) 2015 - 2020  Davide Altomare and David Loris <http://www.channelattribution.net>

# ChannelAttribution is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ChannelAttribution is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ChannelAttribution.  If not, see <http://www.gnu.org/licenses/>.

require(ChannelAttribution)
require(shiny)
require(DT)
require(data.table)
require(ggplot2)

env0=new.env()
env0$exe_demo=0
env0$R=0
data(PathData,envir=env0)

CAapp=function(){
   
 ca_app=shinyApp(
 
 ui = bootstrapPage(
  navbarPage(strong("CHANNEL ATTRIBUTION TOOL"), id="InOut",
 
   tabPanel("Input",
   
    fluidPage(
    
     fluidRow(
      column(2, "SELECT INPUT",
  	       tags$hr(),
  		   actionButton("demoData", "Load Demo Data"),
  	       tags$hr(),
           fileInput('file1', 'Load Input File',
                        accept=c('text/csv', 'text/comma-separated-values,text/plain', '.csv')),
           radioButtons('sep', 'Path Separator', c(Comma=',',Semicolon=';',Tab='\t'),'Semicolon'),
           tags$hr(),
  		   uiOutput('var_path'),
  		   uiOutput('var_conv'),
  		   uiOutput('var_value'),
  		   uiOutput('var_null'),
  		   tags$hr(),
		   selectInput("order", "Markov model order:",c("1","2","3","4","5"),"1"),
		   tags$hr(),
            actionButton(inputId="runButton", "Run")
           ),
      
      column(10, "VIEW INPUT (FIRST 100 ROW)",  tags$hr(),
            tabPanel('Data', dataTableOutput('Data'))
      )
             
     )#end fluidrow
      
   
    )#end fluidpage
      
   ),#end tabpanel
   
   
   tabPanel("Output",
   
    fluidPage(
              
     fluidRow(
       
       column(3,
              selectInput("dataout", "Choose Output:", choices=c("Results")),
              downloadButton('downloadData', 'Download')
              ),
    
       column(8, "View Output", tags$hr(),
  	 
  	        plotOutput('plot1'),
  	        br(),
  			br(),
  		    plotOutput('plot2'),
  			br(),
  			br(),
             tabPanel('Results', dataTableOutput('R'))
       )
         
     )
    )          
 
   )#end tabsetpanel  
   
  )#end navbarpage 
 
 
 ), #end ui
 
 server=function(input, output, session){ 
  
    observe({
     if(input$runButton>0) {
      updateTabsetPanel(session, "InOut", selected = "Output")
     }else{
      updateTabsetPanel(session, "InOut", selected = "Input")
     }
    })
   
    #Demo Data
    execute=observeEvent(input$demoData, {
   
	 env0$exe_demo=1
	     		
     output$Data=renderDataTable({
 	 env0$Data
     }, options=list(pageLength=10))
     
     output$var_path=renderUI({
      selectInput('var_path', 'Path Variable',c("",colnames(env0$Data)),selected="path")
     })
    
     output$var_conv=renderUI({
      selectInput('var_conv', 'Conversion Variable',c("",colnames(env0$Data)),selected="total_conversions")
     })
    
     output$var_value=renderUI({
      selectInput('var_value', 'Value Variable',c("",colnames(env0$Data)),selected="total_conversion_value")
     })
    
     output$var_null=renderUI({
      selectInput('var_null', 'Null Variable',c("",colnames(env0$Data)),selected="total_null")
     })
         
    })
  
    execute=observeEvent(input$file1, { 
 	
	 env0$exe_demo=0
     
 	 #Load Data
      output$Data=renderDataTable({
        	 
        inFile=input$file1
 	    if(is.null(inFile)){return(NULL)}
 	    #tmp0=readLines(con=inFile$datapath, n=200)
		tab0=fread(inFile$datapath,sep=input$sep,nrows=200) 	    
		#tab0=fread(paste0(tmp0,collapse="\n "),sep=input$sep,nrows=100)
 	      
      }, options=list(pageLength=10))
      
      
      output$var_path=renderUI({
        inFile=input$file1
        if(is.null(inFile)){return(NULL)}
        #tmp0=readLines(con=inFile$datapath, n=200)
		# tab0=fread(inFile$datapath,sep=input$sep,nrows=200) 
 	    tab0=fread(inFile$datapath,sep=input$sep,nrows=1)
        selectInput('var_path', 'Path Variable', c("",colnames(tab0)))
      })
      
      output$var_conv=renderUI({
        inFile=input$file1
        if(is.null(inFile)){return(NULL)}
        #tmp0=readLines(con=inFile$datapath, n=200)
		tab0=fread(inFile$datapath,sep=input$sep,nrows=1)
 	    #tab0=fread(paste0(tmp0,collapse="\n "),sep=input$sep,nrows=1)
        selectInput('var_conv', 'Conversion Variable', c("",colnames(tab0)))
      })
      
      output$var_value=renderUI({
        inFile=input$file1
        if(is.null(inFile)){return(NULL)}
        #tmp0=readLines(con=inFile$datapath, n=200)
		tab0=fread(inFile$datapath,sep=input$sep,nrows=1)
 	    #tab0=fread(paste0(tmp0,collapse="\n "),sep=input$sep,nrows=1)
        selectInput('var_value', 'Value Variable', c("",colnames(tab0)))
      })
      
      output$var_null=renderUI({
        inFile=input$file1
        #tmp0=readLines(con=inFile$datapath, n=200)
		tab0=fread(inFile$datapath,sep=input$sep,nrows=1)
 	    #tab0=fread(paste0(tmp0,collapse="\n "),sep=input$sep,nrows=1)
        selectInput('var_null', 'Null Variable', c("",colnames(tab0)))
      })
    
    
    
    
    })
  
    datasetOutput=reactive({
      switch(input$dataout,
             "Results" = "R")
    })
   
    
    output$downloadData=downloadHandler(
      filename = function(){ 
        paste0(input$dataout, '.csv')
      },
      content=function(file){
        #out=fread(paste0(datasetOutput(),".csv"), header=TRUE, sep=";")
        write.table(env0$R, file, col.names=TRUE, row.names=FALSE, quote=FALSE, sep=";")
      }
    )
    
    
    execute=observeEvent(input$runButton, {
      
      
      withProgress(message = 'Executing: ', value = 0, {
  
 
 	   incProgress(1/2, detail="Start (1/2)")
               
        if(env0$exe_demo==0){
         env0$Data=fread(input$file1$datapath, header=TRUE, sep=input$sep)
        }
        
        if(input$var_null!=""){var_null=input$var_null}else{var_null=NULL}
        if(input$var_value!=""){var_value=input$var_value}else{var_value=NULL}
         
        #HEURISTIC MODELS
        H=heuristic_models(env0$Data,input$var_path,input$var_conv,var_value=var_value)
        setDT(H)
        
        #MARKOV MODEL
        M=markov_model(env0$Data,input$var_path,input$var_conv,var_value=var_value,var_null=var_null,order=as.numeric(input$order))
        setDT(M)
 	     
        setkeyv(H,"channel_name")
        setkeyv(M,"channel_name")
        env0$R=merge(H,M,all=TRUE)
       
        if(input$var_value!=""){
         setnames(env0$R,c("total_conversion","total_conversion_value"),c("markov_conversions","markov_value"))
        }else{
         setnames(env0$R,c("first_touch","last_touch","linear_touch","total_conversions"),c("first_touch_conversions","last_touch_conversions","linear_touch_conversions","markov_conversions"))
        }
        
        # write.table(env0$R, "R.csv", col.names=TRUE, row.names=FALSE, quote=FALSE, sep=";")
           
        #PLOT TOTAL CONVERSIONS
        
        R1=env0$R[,c("channel_name","first_touch_conversions","last_touch_conversions","linear_touch_conversions","markov_conversions"),with=FALSE]
        lnm=length(colnames(R1))
        setnames(R1,c("channel_name","first_touch","last_touch","linear_touch","markov_model"))
        
        R1=melt(R1,id="channel_name")
        	   
        P1=ggplot(R1, aes_string("channel_name", "value", fill = "variable"))
        P1=P1 + 
           geom_bar(stat="identity", position = "dodge") + 
           ggtitle("Total Conversions") +
           theme(axis.title.x = element_text(vjust=-2))+
           theme(axis.title.y = element_text(vjust=+2))+
           theme(title = element_text(vjust=2))+
           theme(text = element_text(size=16)) + 
           theme(plot.title=element_text(size=20)) +
           labs(fill="") +
           ylab("") +
           xlab("")
           
        #PLOT TOTAL VALUE  
        
        if(input$var_value!=""){
        
         R2=env0$R[,c("channel_name","first_touch_value","last_touch_value","linear_touch_value","markov_value"),with=FALSE]
         lnm=length(colnames(R2))
         setnames(R2,1:lnm,c("channel_name","first_touch","last_touch","linear_touch","markov_model"))
        
        }else{
        
         R2=env0$R[,c("channel_name","first_touch_conversions","last_touch_conversions","linear_touch_conversions","markov_conversions"),with=FALSE]
         lnm=length(colnames(R2))
         setnames(R2,1:lnm,c("channel_name","first_touch","last_touch","linear_touch","markov_model"))
         R2[,c("first_touch","last_touch","linear_touch","markov_model"):=0]
        
        }
               
        R2=melt(R2,id="channel_name")
        
        P2=ggplot(R2, aes_string("channel_name", "value", fill = "variable")) 
        P2=P2 +  
           geom_bar(stat="identity", position = "dodge") + 
           ggtitle("Total Conversion Value") +
           theme(axis.title.x = element_text(vjust=-2))+
           theme(axis.title.y = element_text(vjust=+2))+
           theme(title = element_text(vjust=2))+
           theme(text = element_text(size=16)) + 
           theme(plot.title=element_text(size=20)) +
           labs(fill="") +
           ylab("") +
           xlab("")
           
        incProgress(2/2, detail="End (2/2)")
 
 	  
        
      })
    
    
  	 output$plot1=renderPlot({
        P1
       })
  	 
  	 output$plot2=renderPlot({
        P2
       })
  	 
  	 output$R=renderDataTable({
        env0$R
       }, options=list(pageLength=10))
  	 
  	 observe({
        updateTabsetPanel(session, "tabsetId", selected = "Output")
       })
       
    })
     
 }#end server
 
 
 )#end App
 
 runApp(ca_app,launch.browser=TRUE)

}
 
 
 

 