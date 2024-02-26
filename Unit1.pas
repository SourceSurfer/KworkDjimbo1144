unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, System.Net.HttpClient, System.JSON,
  System.Net.URLClient, System.Net.HttpClientComponent, System.Threading;


type
  TForm1 = class(TForm)
    Button1: TButton;
    StringGrid1: TStringGrid;
    NetHTTPClient1: TNetHTTPClient;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    function SendRequestUsingJSONConfig(const FilePath: string): TJSONArray;
    procedure PopulateStringGrid(JSONArray: TJSONArray);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}


/// <summary>
/// Загружает объект JSON из файла.
/// </summary>
/// <param name="FilePath">Путь к файлу JSON.</param>
/// <returns>Загруженный TJSONObject.</returns>
function LoadJSONObjectFromFile(const FilePath: string): TJSONObject;
var
  FileContent: TStringList;
  JSONString: string;
begin
  FileContent := TStringList.Create;
  try
    FileContent.LoadFromFile(FilePath);
    JSONString := FileContent.Text;
    Result := TJSONObject.ParseJSONValue(JSONString) as TJSONObject;
  finally
    FileContent.Free;
  end;
end;

/// <summary>
/// Анализирует строку JSON в TJSONArray.
/// </summary>
/// <param name="JSONString">Строка JSON для анализа.</param>
/// <returns>Разобранный TJSONArray.</returns>
function ParseJSONResponse(const JSONString: string): TJSONArray;
begin
  Result := TJSONObject.ParseJSONValue(JSONString) as TJSONArray;
end;

/// <summary>
/// Отправляет запрос, используя конфигурацию, указанную в файле JSON, и возвращает ответ в виде TJSONArray.
/// </summary>
/// <param name="FilePath">Путь к файлу конфигурации JSON.</param>
/// <returns>Данные ответа в виде TJSONArray.</returns>
function TForm1.SendRequestUsingJSONConfig(const FilePath: string): TJSONArray;
var
  JSONObject: TJSONObject;
  Params: TStringList;
  URL: string;
  Response: IHTTPResponse;
begin
  JSONObject := LoadJSONObjectFromFile(FilePath);
  if Assigned(JSONObject) then
  try
    URL := JSONObject.GetValue<string>('url') + '/' + JSONObject.GetValue<string>('resource');
    Params := TStringList.Create;
    try
      for var Param in JSONObject.GetValue<TJSONArray>('parameters') do
      begin
        var ParamObj := Param as TJSONObject;
        Params.Values[ParamObj.GetValue<string>('name')] := ParamObj.GetValue<string>('value');
      end;
      Response := NetHTTPClient1.Post(URL, Params);
      if Response.StatusCode = 200 then
        Result := ParseJSONResponse(Response.ContentAsString)
      else
        ShowMessage('Error: ' + Response.StatusCode.ToString + ' - ' + Response.ContentAsString);
    finally
      Params.Free;
    end;
  finally
    JSONObject.Free;
  end
  else
    ShowMessage('Не удалось загрузить или проанализировать конфигурацию JSON.');
end;


procedure TForm1.Button1Click(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  FilePath: string;
  UserChoice: Integer;
begin
  FilePath := '';
  OpenDialog := TOpenDialog.Create(nil);
  try
    ShowMessage('Пожалуйста, выберите расположение файла JSON.');

    OpenDialog.InitialDir := GetCurrentDir;
    OpenDialog.Filter := 'JSON Files|*.json';
    OpenDialog.DefaultExt := 'json';
    OpenDialog.Title := 'Select a JSON File';

    if OpenDialog.Execute then
    begin
      FilePath := OpenDialog.FileName;
    end;
  finally
    OpenDialog.Free;
  end;

  if FilePath <> '' then
  begin
    Label1.Visible := True;


    TTask.Run(procedure
    begin

      Sleep(500);

      TThread.Synchronize(nil, procedure
        begin
           PopulateStringGrid(SendRequestUsingJSONConfig(FilePath));
           Label1.Visible := False;
        end);
    end);



  end
  else
    ShowMessage('Ни один файл не был выбран.');
end;


/// <summary>
/// Заполняет TStringGrid данными из массива JSON.
/// </summary>
/// <param name="JSONArray">Массив JSON, содержащий данные для заполнения сетки.</param>
procedure TForm1.PopulateStringGrid(JSONArray: TJSONArray);
begin
  with StringGrid1 do
  begin
    ColCount := 6; // ID, Game Name, Pic Link, Game Type, Game Launcher, Start Count
    RowCount := JSONArray.Count + 1;

    Cells[0, 0] := 'ID';
    Cells[1, 0] := 'Game Name';
    Cells[2, 0] := 'Pic Link';
    Cells[3, 0] := 'Game Type';
    Cells[4, 0] := 'Game Launcher';
    Cells[5, 0] := 'Start Count';

    for var i := 0 to JSONArray.Count - 1 do
    begin
      var JSONObj := JSONArray.Items[i] as TJSONObject;
      Cells[0, i + 1] := JSONObj.GetValue<string>('id');
      Cells[1, i + 1] := JSONObj.GetValue<string>('game_name');
      Cells[2, i + 1] := JSONObj.GetValue<string>('pic_link');
      Cells[3, i + 1] := JSONObj.GetValue<string>('game_type');
      Cells[4, i + 1] := JSONObj.GetValue<string>('game_launcher');
      Cells[5, i + 1] := JSONObj.GetValue<string>('start_count');
    end;
  end;
end;

end.

