function varargout = ceo_tool(varargin)
% CEO_TOOL MATLAB code for ceo_tool.fig
%      CEO_TOOL, by itself, creates a new CEO_TOOL or raises the existing
%      singleton*.
%
%      H = CEO_TOOL returns the handle to a new CEO_TOOL or the handle to
%      the existing singleton*.
%
%      CEO_TOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CEO_TOOL.M with the given input arguments.
%
%      CEO_TOOL('Property','Value',...) creates a new CEO_TOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ceo_tool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ceo_tool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ceo_tool
%kathryn test hi
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ceo_tool_OpeningFcn, ...
                   'gui_OutputFcn',  @ceo_tool_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ceo_tool is made visible.
function ceo_tool_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ceo_tool (see VARARGIN)

% Choose default command line output for ceo_tool
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%% Get and display ISS latitude and longitude
update_iss_coords(handles)

%% Get target data from XML file

% Assumes the XML file is in the same directory as this file.
xmlDoc = xmlread('EOSitesDaily.xml');
doc = xmlwrite(xmlDoc);
a=strsplit(doc,{'<wmc__TEOSite Category="Daily"','</wmc__TEOSite>'});
no_of_targets = (length(a)-1)/2;
sites(no_of_targets) = struct('site_no',[], 'passover_time',[], 'target_name',[], 'lat',[], 'long', [], 'notes', [], 'lenses', [], 'closest_approach', []);

for i=1:no_of_targets
    b = char(a(2*i));
    
    %site_no
    sites(i).site_no=i;
    
    %target_name
    namearr = strsplit(b,'Nomenclature="');
    name = char(namearr(2));
    namearr2 = strsplit(name,'"');
    name = char(namearr2(1));
    sites(i).target_name=name;
    
    %passover_time
    notesarr = strsplit(b, {'Notes="','>'});
    notes = char(notesarr(2));
    timearr = strsplit(notes, ';');
    sites(i).passover_time=char(timearr(1));
    
    %lenses
    lenses = char(timearr(2));
    lensarr = strsplit(lenses, ': ');
    lenses = char(lensarr(2));
    sites(i).lenses=lenses;
    
    %notes
    notes2=strsplit(char(timearr(3)),'"');
    sites(i).notes=char(notes2(1));
    
    %lat and long and closest_approach
    if(length(timearr)>3)
        latlon = char(timearr(4));
        latarr = strsplit(latlon,'lat: ');
        lati = char(latarr(2));
        lonarr = strsplit(lati,{', lon:',' '});
        lati = char(lonarr(1));
        longi = char(lonarr(2));
        close = char(lonarr(4));
        close = close(1:end-1);
        sites(i).lat=lati;
        sites(i).long=longi;
        sites(i).closest_approach=close;
    end
end

% Save sites data so it can be accessed by other functions.
handles.sites = sites;
guidata(hObject, handles)

% Populate the selection box where users pick targets to view data for.
for i=1:no_of_targets
    if i == 1
        all_targets = [];
    else
        all_targets = cellstr(get(handles.listbox3,'String'));
    end
    set(handles.listbox3, 'String', vertcat(all_targets, [num2str(i) '. ' sites(i).target_name]));
end

% By default, display details about the first target.
set_curr_target(1, handles);

function update_iss_coords(handles)
%% Get latitude and longitude
latlong=urlread('http://api.open-notify.org/iss-now.json');
a=strsplit(latlong,'\n');

latstr = char(a(5));
latarr = strsplit(latstr);
lat = char(latarr(3));
latitude = lat(1:end-1);

longstr = char(a(4));
longarr = strsplit(longstr);
long = char(longarr(3));
longitude = long(1:end-1);

% Display the ISS coordinates.
if ~isempty(latitude)|| ~isempty(longitude)
    set(handles.input_lat,'string',{num2str(latitude)})
    set(handles.input_long,'string',{num2str(longitude)})
end

% --- Updates the information in the information box given the target
% number requested by the user.
function set_curr_target(target_num, handles)
% target_num the index of the target the user selected
% handles    structure with handles and user data (see GUIDATA)

sites = handles.sites;
set(handles.selected_name, 'string', sites(target_num).target_name)
set(handles.selected_lat, 'string', sites(target_num).lat)
set(handles.selected_long, 'string', sites(target_num).long)
set(handles.selected_passtime, 'string', sites(target_num).passover_time)
set(handles.selected_lens, 'string', sites(target_num).lenses)
set(handles.selected_notes, 'string', strtrim(sites(target_num).notes))
set(handles.curr_target_str, 'string', [num2str(target_num) ' of ' num2str(length(sites))])


% --- Outputs from this function are returned to the command line.
function varargout = ceo_tool_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on selection change in listbox3.
function listbox3_Callback(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = cellstr(get(hObject,'String')); %returns listbox3 contents as cell array
val = contents{get(hObject,'Value')}; %returns selected item from listbox3
curr_target_index = val(1);
set_curr_target(str2num(curr_target_index), handles);
%change data within selected target panel

% --- Executes during object creation, after setting all properties.
function listbox3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in update_iss_button.
function update_iss_button_Callback(hObject, eventdata, handles)
% hObject    handle to update_iss_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_iss_coords(handles)


% --- Executes during object deletion, before destroying properties.
function listbox3_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over input_long.
function input_long_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to input_long (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
