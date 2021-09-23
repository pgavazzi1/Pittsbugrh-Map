import pandas as pd
import numpy as np
# import streamlit as st

import dash
# from dash.dependencies import Input, Output, State
import dash_core_components as dcc
import dash_html_components as html 

import geopandas as gpd
import folium
import matplotlib.pyplot as plt

# import json stuff?
import requests


##########################################################
################### DATA AND MAP SETUP ###################

m = pd.read_csv('merge_data_allegheny_map.csv')

# Add geometry data to dataframe... TODO: save in a seperate file
data = 'https://services1.arcgis.com/vdNDkVykv9vEWFX4/arcgis/rest/services/AlleghenyCountyMunicipalBoundaries/FeatureServer/0/query?where=1%3D1&outFields=*&geometry=&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelIntersects&outSR=4326&f=geojson'
response = requests.get(data)
df = gpd.read_file('geo_data.json')
df['geometry']
m['geometry'] = df['geometry']


# Color pallet for each slection option
regions_colors = {
  'AA': 'blue',
  'ES': 'green',
  'MV': 'red',
  'NH': 'yellow',
  'PGH': 'grey' ,
  'SH':  'orange'
}

cog_colors = {
    'Allegheny Valley North': 'Coral' ,
    'Quaker Valley': 'DarkViolet',
    'nan': 'DeepSkyBlue', 
    'North Hills': 'LightSalmon',
    'Char-West': 'OrangeRed', 
    'Turtle Creek Valley': 'Cornsilk',
    'Steel Rivers': 'Green', 
    'South Hills Area': 'grey'
}

school_colors = {
    'Allegheny Valley': 'balck',
    'Quaker Valley': 'Aqua',
    'Fox Chapel Area': 'BlueViolet',
    'North Allegheny': 'CadetBlue',
    'Avonworth': 'Coral',
    'Pine-Richland': 'Cyan',
    'Deer Lakes': 'Chocolate',
    'Highlands': 'Cornsilk',
    'Northgate': 'DarkBlue',
    'Shaler Area': 'DarkGrey',
    'Cornell': 'DarkGreen',
    'Wilkinsburg': 'DarkCyan',
    'Plum Borough': 'DeepPink',
    'Woodland Hills': 'DeepSkyBlue',
    'North Hills': 'DarkViolet',
    'Gateway': 'DimGray',
    'Chartiers Valley': 'DodgerBlue',
    'Riverview': 'DimGry',
    'Montour': 'FloralWhite',
    'Clairton City': 'ForestGreen',
    'West Jefferson Hills': 'FireBrick',
    'East Allegheny': 'GhostWhite',
    'McKeesport Area': 'Gold',
    'South Allegheny': 'Gray',
    'Duquesne City': 'Lavender',
    'Elizabeth Foreward': 'LawnGreen',
    'South Park': 'LavenderBlush',
    'West Mifflin Area': 'LemonChiffon',
    'City of Pittsburgh': 'LightBlue',
    'Steel Valley': 'LightCoral',
    'Keystone Oaks': 'LightCyan',
    'Baldwin-Whitehall': 'LightBlue',
    'Brentwood Borough': 'LightSalmon',
    'Mt. Lebanon': 'Linen',
    'Upper St. Clair Area': 'Maroon',
    'Sto-Rox': 'Magenta',
    'Carlynton': 'Orange',
    'Moon Area': 'OrangeRed',
    'West Allegheny': 'Orchid',
    'Fort Cherry': 'PaleGreen',
    'South Fayete Township': 'PaleTurquoise',
    'Hampton Township': 'PapayaWhip',
    'Bethel Park': 'PeachPuff',
    'Penn-Trafford': 'Pink',
    'Penn Hills': 'Plum'
}




################################################
################### APP CODE ###################

app = dash.Dash(__name__) 
app.layout = html.Div(children=[

    # Title
    html.H1('Allegheny County Municipal Map: Police Contracts', className="main-title"),


    # Side Bar
    html.Div(
        children=[
            html.P('As a part of the Allegheny County Policing Project (ACPP), this tool allows users to learn more about the policing practices and procedures of various municipalities through an interactive map'),
            html.H4('Choose from these options'),
            dcc.Dropdown(
                id='sort-dropdown',
                options=[
                    {'label': 'Region', 'value': 'REGION'},
                    {'label': 'Council of Governments (COG)', 'value': 'COG'},
                    {'label': 'School District', 'value': 'SCHOOLD'}
                ],
                value='REGION'
            ),
        ],
        className="side-bar"),

    # Map
    html.Div(
        children=[
            html.Div(id='map-test')
        ],
        className="all_map"),

    html.Div(children=[
                    html.P("    "),
                ],
                className="blankspace"),

    html.Div(children=[
                    html.H3("Phrase found in contract"),
                    dcc.RadioItems(
                        id='word-selector',
                        options=[
                            {'label': 'time limit', 'value': 'time limit'},
                            {'label': 'subpoena', 'value': 'subpoena'},
                            {'label': 'false arrest', 'value': 'false arrest'},
                            {'label': 'discipline', 'value': 'discipline'},
                            {'label': 'destroy', 'value': 'destroy'},
                            {'label': 'release', 'value': 'release'}
                        ],
                        value=''
                    ),
                ],
                className="selector"),

    html.Div(children=[
                html.Button('Reset', id='button'),
                html.Div(id='reset')
            ],
            className="reset")
    ]
)

# Resets the keyword
@app.callback(
    dash.dependencies.Output(component_id='reset', component_property='children'),
    dash.dependencies.Input('button', 'n_clicks'))
def update_output_div(n_clicks):
    print('Hi')

# Update every time a new keyword or sorting type is selected
@app.callback(
    dash.dependencies.Output('map-test', 'children'),
    dash.dependencies.Input('word-selector', 'value'),
    dash.dependencies.Input('sort-dropdown', 'value'))
def update_output(keyword, sort_type):

    myMap = folium.Map(location=[40.440, -79.995], zoom_start=9, tiles="CartoDB positron", tooltip = 'This tooltip will appear on hover')


    #Create a polygon for each municipality
    for _, r in m.iterrows():
        sim_geo = gpd.GeoSeries(r['geometry']).simplify(tolerance=0.001)
        geo_j = sim_geo.to_json()

        # Find the correct color for the region
        if (sort_type == "REGION"):
            color = regions_colors[r['REGION']]
        elif (sort_type == "SCHOOLD"):
            color = school_colors[r['SCHOOLD']]
        elif (sort_type == "COG"):
            if (type(r['COG']) != float):
                color = cog_colors[r['COG']]
            else:
                color = cog_colors['nan']

        # Outline places that contain current keyword
        # TODO: Add reset button, and also figure out how only bold red places
        if keyword in str(r['Keywords.found.in.contract']).split(", "):
            color2 = 'red' 
        else:  
            color2 = 'black'        

        geo_j = folium.GeoJson(data=geo_j, tooltip=r['LABEL'] ,                          
                                style_function=lambda x, fillColor=color, bordercolor=color2: {
                                    "fillColor": str(fillColor),
                                    "color": bordercolor
                                })
        # Popup code
        folium.Popup(r['LABEL'] 
                     + "<br>"
                    # TODO: Make sure links connect to internet, and pull up on whole screen
                     + '<a  href=' + str(r['Link.to.police.department']) +'>Link to police department website</a>'
                     + "<br> Total number of Full Time Police Officers as of 2019:" 
                     + str(r['Total.Number.Police.Officers..as.of.2019.']) 
                     + "<br> Police Bill of Rights?: " + str(r['Do.they.use.a.police.bill.of.rights.'])
                     + "<br> <br> Problematic phrases in police union contracts: " + str(r['Keywords.found.in.contract']),
                     max_width=250, max_height=450).add_to(geo_j)
        geo_j.add_to(myMap)

    myMap.save("test.html")

    return html.Iframe(srcDoc = open('test.html', 'r').read(), className="map")


if __name__ == "__main__":
    app.run_server(debug=True)
