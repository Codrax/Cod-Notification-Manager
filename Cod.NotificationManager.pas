{***********************************************************}
{                Codruts Notification Manager               }
{                                                           }
{                        version 1.1                        }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{              Copyright 2023 Codrut Software               }
{***********************************************************}

{$SCOPEDENUMS ON}

unit Cod.NotificationManager;

interface
  uses
  // System
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Forms, IOUtils,

  // Windows RT (Runtime)
  Winapi.Winrt,
  Winapi.Winrt.Utils,
  Winapi.DataRT,
  Winapi.UI.Notifications,

  // Winapi
  Winapi.CommonTypes,
  Winapi.Foundation,

  // Cod Utils
  Cod.Registry;

  type
    // Cardinals
    TSoundEventValue = (
      Default,
      NotificationDefault,
      NotificationIM,
      NotificationMail,
      NotificationReminder,
      NotificationSMS,
      NotificationLoopingAlarm,
      NotificationLoopingAlarm2,
      NotificationLoopingAlarm3,
      NotificationLoopingAlarm4,
      NotificationLoopingAlarm5,
      NotificationLoopingAlarm6,
      NotificationLoopingAlarm7,
      NotificationLoopingAlarm8,
      NotificationLoopingAlarm9,
      NotificationLoopingAlarm10,
      NotificationLoopingCall,
      NotificationLoopingCall2,
      NotificationLoopingCall3,
      NotificationLoopingCall4,
      NotificationLoopingCall5,
      NotificationLoopingCall6,
      NotificationLoopingCall7,
      NotificationLoopingCall8,
      NotificationLoopingCall9,
      NotificationLoopingCall10
    );

    {$SCOPEDENUMS OFF}
    TWinBoolean = (WinDefault, WinFalse, WinTrue);
    {$SCOPEDENUMS ON}
    TImagePlacement = (Default, Hero, LogoOverride);
    TImageCrop = (Default, Circle);
    TInputType = (Text, Selection);

    TXMLInterface = Xml_Dom_IXmlDocument;

    // Records
    (* https://learn.microsoft.com/en-us/uwp/schemas/tiles/toastschema/element-header *)
    TNotificationHeader = record
      ID: string;
      Title: string;
      Arguments: string;
      ActivationType: string;

      function ToXML: string;
    end;

    (* https://learn.microsoft.com/en-us/windows/apps/design/shell/tiles-and-notifications/adaptive-interactive-toasts?tabs=xml *)
    TInputItem = record
      ID: string;
      Content: string;

      function ToXML: string;
    end;

    TNotificationInput = record
      ID: string;
      InputType: TInputType;
      PlaceHolder: string;
      Title: string;

      Selections: TArray<TInputItem>;

      function ToXML: string;
    end;

    (* https://learn.microsoft.com/en-us/uwp/schemas/tiles/toastschema/element-image *)
    TNotificationImage = record
      ImageQuery: string;
      Alt: string;
      Source: string; // URL or Local file path
      Placement: TImagePlacement;
      HintCrop: TImageCrop;

      function ToXML: string;
    end;

    (* https://learn.microsoft.com/en-us/uwp/schemas/tiles/toastschema/element-audio *)
    TNotificationAudio = record
      Sound: TSoundEventValue;
      Loop: TWinBoolean;
      Silent: TWinBoolean;

      function ToXML: string;
    end;

    (* https://learn.microsoft.com/en-us/uwp/schemas/tiles/toastschema/element-progress *)
    TNotificationProgress = record
      Title: string;
      Status: string; // Name, such as "installing" or "downloading"
      Value: single; // 0.0 - 1.0
      ValueOverride: string; // Override percentage text

      function ToXML: string;
    end;

    // Classes
    TNotification = class(TObject)
    private
      FTitle: string;
      FText: string;
      FTextExtra: string;

      FXML: TXMLInterface;

      FToast: IToastNotification;
      FPosted: boolean;

      function BuildXMLDoc: TXMLInterface;

    public
      // Basic
      property Title: string read FTitle write FTitle;
      property Text: string read FText write FText;
      property TextExtra: string read FTextExtra write FTextExtra;

      // Advanced
      var
      Image: TNotificationImage;
      Audio: TNotificationAudio;
      Progress: TNotificationProgress;
      Input: TNotificationInput;
      Header: TNotificationHeader;

      property Toast: IToastNotification read FToast;
      property Posted: boolean read FPosted;

      // Procs
      function ToXML: string;

      procedure UpdateToastInterface; // rebuilds interface
      procedure ClearToastInterface;

      // Constructors
      constructor Create;
      destructor Destroy; override;

    end;

    TNotificationManager = class(TObject)
    private
      const
        VALUE_NAME = 'DisplayName';
        VALUE_ICON = 'IconUri';
        VALUE_ACTIVATOR = 'DisplayName';
        VALUE_SETTINGS = 'ShowInSettings';
        VALUE_LAUNCH = 'LaunchUri';

      var
      FNotifier: IToastNotifier;
      FAppID: string;

      FRegPath: string;
      FIsSystemIcon: boolean;
      FCreateIconCache: boolean;

      // Notifier
      procedure RebuildNotifier;

      // Registry
      function HasRegistryRecord: boolean;
      function FormatRegistry(AIdentifier: string): string;

      function GetModuleName: string;
      function CreateAppIconCache: string;
      procedure DeleteIconCache;

      // Getters
      function GetAppIcon: string;
      function GetAppName: string;
      function GetAppLaunch: string;
      function GetAppActivator: string;
      function GetShowSettings: boolean;

      // Setters
      procedure SetAppID(const Value: string);
      procedure SetAppIcon(const Value: string);
      procedure SetAppName(const Value: string);
      procedure SetAppLaunch(const Value: string);
      procedure SetAppActivator(const Value: string);
      procedure SetGetShowSettings(const Value: boolean);

    public
      // Notificaitons
      procedure ShowNotification(Notification: TNotification);
      procedure HideNotification(Notification: TNotification);

      // Settings
      property CreateIconCache: boolean read FCreateIconCache write FCreateIconCache;

      // App
      property ApplicationIdentifier: string read FAppID write SetAppID; // set first!
      property ApplicationName: string read GetAppName write SetAppName;
      property ApplicationIcon: string read GetAppIcon write SetAppIcon;
      property ApplicationLaunch: string read GetAppLaunch write SetAppLaunch;
      property CustomActivator: string read GetAppActivator write SetAppActivator;
      property ShowInSettings: boolean read GetShowSettings write SetGetShowSettings;

      // Utils
      procedure ResetAppIcon;
      function CreateNewNotification: TNotification;
      procedure CreateRegistryRecord;
      procedure DeleteRegistryRecord;

      // Constructors
      constructor Create;
      destructor Destroy; override;
    end;

  // Utils
  function AudioTypeToString(AType: TSoundEventValue): string;
  function WinBooleanToString(AType: TWinBoolean): string;
  function StringToRTString(Value: string): HSTRING; // Needs to be freed with WindowsDeleteString

  // XML
  function EncapsulateXML(Name: string; Container: string; Tags: string = ''): string;
  function CreateNewXMLInterface: TXMLInterface;
  function StringToXMLDocument(Str: string): TXMLInterface;
  function XMLDocumentToString(AXML: TXMLInterface): string;
  procedure XMLDocumentEdit(AXML: TXMLInterface; NewContents: string);

implementation

const
  NOTIF_BUILD_ERR = 'Notification toast has not been built. E:UpdateToastInterface';

{ TNotificationAudio }

function AudioTypeToString(AType: TSoundEventValue): string;
begin
  case AType of
    TSoundEventValue.NotificationDefault: Result := 'ms-winsoundevent:Notification.Default';
    TSoundEventValue.NotificationIM: Result := 'ms-winsoundevent:Notification.IM';
    TSoundEventValue.NotificationMail: Result := 'ms-winsoundevent:Notification.Mail';
    TSoundEventValue.NotificationReminder: Result := 'ms-winsoundevent:Notification.Reminder';
    TSoundEventValue.NotificationSMS: Result := 'ms-winsoundevent:Notification.SMS';
    TSoundEventValue.NotificationLoopingAlarm: Result := 'ms-winsoundevent:Notification.Looping.Alarm';
    TSoundEventValue.NotificationLoopingAlarm2: Result := 'ms-winsoundevent:Notification.Looping.Alarm2';
    TSoundEventValue.NotificationLoopingAlarm3: Result := 'ms-winsoundevent:Notification.Looping.Alarm3';
    TSoundEventValue.NotificationLoopingAlarm4: Result := 'ms-winsoundevent:Notification.Looping.Alarm4';
    TSoundEventValue.NotificationLoopingAlarm5: Result := 'ms-winsoundevent:Notification.Looping.Alarm5';
    TSoundEventValue.NotificationLoopingAlarm6: Result := 'ms-winsoundevent:Notification.Looping.Alarm6';
    TSoundEventValue.NotificationLoopingAlarm7: Result := 'ms-winsoundevent:Notification.Looping.Alarm7';
    TSoundEventValue.NotificationLoopingAlarm8: Result := 'ms-winsoundevent:Notification.Looping.Alarm8';
    TSoundEventValue.NotificationLoopingAlarm9: Result := 'ms-winsoundevent:Notification.Looping.Alarm9';
    TSoundEventValue.NotificationLoopingAlarm10: Result := 'ms-winsoundevent:Notification.Looping.Alarm10';
    TSoundEventValue.NotificationLoopingCall: Result := 'ms-winsoundevent:Notification.Looping.Call';
    TSoundEventValue.NotificationLoopingCall2: Result := 'ms-winsoundevent:Notification.Looping.Call2';
    TSoundEventValue.NotificationLoopingCall3: Result := 'ms-winsoundevent:Notification.Looping.Call3';
    TSoundEventValue.NotificationLoopingCall4: Result := 'ms-winsoundevent:Notification.Looping.Call4';
    TSoundEventValue.NotificationLoopingCall5: Result := 'ms-winsoundevent:Notification.Looping.Call5';
    TSoundEventValue.NotificationLoopingCall6: Result := 'ms-winsoundevent:Notification.Looping.Call6';
    TSoundEventValue.NotificationLoopingCall7: Result := 'ms-winsoundevent:Notification.Looping.Call7';
    TSoundEventValue.NotificationLoopingCall8: Result := 'ms-winsoundevent:Notification.Looping.Call8';
    TSoundEventValue.NotificationLoopingCall9: Result := 'ms-winsoundevent:Notification.Looping.Call9';
    TSoundEventValue.NotificationLoopingCall10: Result := 'ms-winsoundevent:Notification.Looping.Call10';

    else Result := '';
  end;
end;

function WinBooleanToString(AType: TWinBoolean): string;
begin
  case AType of
    TWinBoolean.WinDefault: Result := 'default';
    TWinBoolean.WinFalse: Result := 'false';
    TWinBoolean.WinTrue: Result := 'true';
  end;
end;

function StringToRTString(Value: string): HSTRING;
begin
  if NOT Succeeded(
    WindowsCreateString(PWideChar(Value), Length(Value), Result)
  )
  then raise Exception.CreateFmt('Unable to create HString for %s', [ Value ] );
end;

function EncapsulateXML(Name: string; Container, Tags: string): string;
var
  TagBegin, TagEnd: string;
begin
  if Container <> '' then
    TagEnd := Format('</%S>', [Name])
  else
    TagEnd := '';

  TagBegin := Format('<%S', [Name]);
  if Tags <> '' then
    TagBegin := Format('%S %S', [TagBegin, Tags]);

  if Container <> '' then
    TagBegin := TagBegin + '>'
  else
    TagBegin := TagBegin + '/>';

  Result := TagBegin + Container + TagEnd;
end;

function StringToXMLDocument(Str: string): TXMLInterface;
begin
  Result := CreateNewXMLInterface;
  XMLDocumentEdit(Result, Str);
end;

function CreateNewXMLInterface: TXMLInterface;
var
  Manager: TToastNotificationManager;
begin
  Manager := TToastNotificationManager.Create;
  try
    Result := Manager.GetTemplateContent(ToastTemplateType.ToastText01);
    XMLDocumentEdit(Result, '<xml />');
  finally
    Manager.Free;
  end;
end;

function XMLDocumentToString(AXML: TXMLInterface): string;
  function HStringToString(Src: HSTRING): String;
  var
    c: Cardinal;
  begin
    c := WindowsGetStringLen(Src);
    Result := WindowsGetStringRawBuffer(Src, @c);
  end;

begin
  Result := HStringToString(
    ( AXML.DocumentElement as Xml_Dom_IXmlNodeSerializer ).GetXml
  );
end;

procedure XMLDocumentEdit(AXML: TXMLInterface; NewContents: string);
var
  hXML: HSTRING;
begin
  hXML := StringToRTString( NewContents );
  try
    (AXML as Xml_Dom_IXmlDocumentIO).LoadXml( hXML );
  finally
    WindowsDeleteString( hXML );
  end;
end;

function TNotificationAudio.ToXML: string;
begin
  Result := '';

  if Sound <> TSoundEventValue.Default then
    Result := Result + 'src="' + AudioTypeToString(Sound) + '" ';

  if Loop <> TWinBoolean.WinDefault then
    Result := Result + 'loop="' + WinBooleanToString(Loop) + '" ';

  if Silent <> TWinBoolean.WinDefault then
    Result := Result + 'silent="' + WinBooleanToString(Silent) + '"';

  // Encapsulate
  if Result <> '' then
    Result := EncapsulateXML('audio', '', Result);
end;

{ TNotification }

function TNotification.BuildXMLDoc: TXMLInterface;
begin
  Result := StringToXMLDocument( ToXML );
end;

procedure TNotification.ClearToastInterface;
begin
  FToast := nil;

  // Reset
  FPosted := false;
end;

constructor TNotification.Create;
begin
  inherited;
  FTitle := 'Hello world!';
  FText := 'This is a notification';

  FXML := CreateNewXMLInterface;
end;

destructor TNotification.Destroy;
begin
  FXML := nil;

  inherited;
end;

function TNotification.ToXML: string;
function TextToXML(Value: string): string;
begin
  if Value <> '' then
    Result := EncapsulateXML('text', Value)
  else
    Result := '';
end;
begin
  Result := '';

  Result := Result + '<toast activationType="protocol">';
    // Visual
    Result := Result + '<visual>';
      Result := Result + '<binding template="ToastGeneric">';
        // Text
        Result := Result + TextToXML(Title);
        Result := Result + TextToXML(Text);
        Result := Result + TextToXML(TextExtra);

        // Extra
        Result := Result + Image.ToXML;
        Result := Result + Progress.ToXML;
      Result := Result + '</binding>';
    Result := Result + '</visual>';

    // Input
    const Input = Input.ToXML;
    if Input <> '' then
    Result := Result + EncapsulateXML('actions', Input);

    // Audio
    Result := Result + Audio.ToXML;

    // Header
    Result := Result + Header.ToXML;
  Result := Result + '</toast>';
end;

procedure TNotification.UpdateToastInterface;
begin
  ClearToastInterface;

  FToast := TToastNotification.CreateToastNotification(BuildXMLDoc);
end;

{ TNotificationProgress }

function TNotificationProgress.ToXML: string;
begin
  Result := '';

  // Check disabled/invalid
  if Status = '' then
    Exit;

  if Title <> '' then
    Result := Result + 'title="' + Title + '" ';

  Result := Result + 'status="' + Status + '" ';
  Result := Result + 'value="' + Value.ToString + '" ';

  if ValueOverride <> '' then
    Result := Result + 'valueStringOverride="' + ValueOverride + '"';

  // Encapsulate
  if Result <> '' then
    Result := EncapsulateXML('progress', '', Result);
end;

{ TNotificationImage }

function TNotificationImage.ToXML: string;
begin
  Result := '';

  // Check disabled/invalid
  if Source = '' then
    Exit;

  if ImageQuery <> '' then
    Result := Result + 'addImageQuery="' + ImageQuery + '" ';

  if Alt <> '' then
    Result := Result + 'alt="' + Alt + '" ';

  Result := Result + 'src="' + Source + '" ';

  case Placement of
    TImagePlacement.Hero: Result := Result + 'placement="hero" ';
    TImagePlacement.LogoOverride: Result := Result + 'placement="appLogoOverride" ';
  end;

  case HintCrop of
    TImageCrop.Circle: Result := Result + 'hint-crop="circle" ';
  end;

  // Encapsulate
  if Result <> '' then
    Result := EncapsulateXML('image', '', Result);
end;

{ TInputItem }

function TInputItem.ToXML: string;
begin
  Result := '';

  // Check disabled/invalid
  if ID = '' then
    Exit;

  Result := Result + 'id="' + ID + '" ';
  Result := Result + 'content="' + Content + '" ';

  // Encapsulate
  if Result <> '' then
    Result := EncapsulateXML('selection', '', Result);
end;

{ TNotificationInput }

function TNotificationInput.ToXML: string;
var
  Inputs: string;
  I: integer;
begin
  Result := '';

  // Check disabled/invalid
  if ID = '' then
    Exit;

  Result := Result + 'id="' + ID + '" ';

  case InputType of
    TInputType.Text: Result := Result + 'type="text" ';
    TInputType.Selection: Result := Result + 'type="selection" ';
  end;

  if PlaceHolder <> '' then
    Result := Result + 'placeHolderContent="' + PlaceHolder + '" ';

  if Title <> '' then
    Result := Result + 'title="' + Title + '" ';

  // Inputs
  Inputs := '';
  if Length(Selections) > 0 then
    for I := 0 to High(Selections) do
      Inputs := Inputs + Selections[I].ToXML;

  // Encapsulate
  if Result <> '' then
    Result := EncapsulateXML('input', Inputs, Result);
end;

{ TNotificationManager }

constructor TNotificationManager.Create;
begin
  // Generate default ID
  ApplicationIdentifier := GetModuleName;
  FCreateIconCache := true;
end;

function TNotificationManager.CreateAppIconCache: string;
const
  NOTIF_FOLDER = 'C:\Users\Codrut\AppData\Local\Microsoft\Windows\Notifications\ActionCenter\';
begin
  Result := Format('%S%S.ico', [NOTIF_FOLDER, ApplicationIdentifier]);

  if not TDirectory.Exists(NOTIF_FOLDER) then
    TDirectory.CreateDirectory(NOTIF_FOLDER);

  Application.Icon.SaveToFile(Result);
end;

function TNotificationManager.CreateNewNotification: TNotification;
begin
  Result := TNotification.Create;
end;

procedure TNotificationManager.CreateRegistryRecord;
begin
  if not HasRegistryRecord then
    // Create
    begin
      TQuickReg.CreateKey( FRegPath );

      SetAppName(''); // module name
      if CreateIconCache then
        ResetAppIcon; // default app icon
    end;
end;

procedure TNotificationManager.DeleteIconCache;
begin
  const Path = GetAppIcon;

  if TFile.Exists(Path) then
    TFile.Delete(Path);

  FIsSystemIcon := true;
end;

procedure TNotificationManager.DeleteRegistryRecord;
begin
  TQuickReg.DeleteKey(FRegPath);

  if FIsSystemIcon then
    DeleteIconCache;
end;

destructor TNotificationManager.Destroy;
begin
  FNotifier := nil;
  inherited;
end;

function TNotificationManager.FormatRegistry(AIdentifier: string): string;
begin
  Result := Format('HKEY_CURRENT_USER\Software\Classes\AppUserModelId\%S', [AIdentifier]);
end;

function TNotificationManager.GetAppActivator: string;
begin
  Result := '';
  if HasRegistryRecord then
    if TQuickReg.ValueExists(FRegPath, VALUE_ICON) then
      Result := TQuickReg.GetStringValue(FRegPath, VALUE_ACTIVATOR);
end;

function TNotificationManager.GetAppIcon: string;
begin
  Result := '';
  if HasRegistryRecord then
    if TQuickReg.ValueExists(FRegPath, VALUE_ICON) then
      Result := TQuickReg.GetStringValue(FRegPath, VALUE_ICON);
end;

function TNotificationManager.GetAppLaunch: string;
begin
  Result := '';
  if HasRegistryRecord then
    if TQuickReg.ValueExists(FRegPath, VALUE_LAUNCH) then
      Result := TQuickReg.GetStringValue(FRegPath, VALUE_LAUNCH);
end;

function TNotificationManager.GetAppName: string;
begin
  Result := '';
  if HasRegistryRecord then
    if TQuickReg.ValueExists(FRegPath, VALUE_NAME) then
      Result := TQuickReg.GetStringValue(FRegPath, VALUE_NAME);
end;

function TNotificationManager.GetModuleName: string;
begin
  Result := ExtractFileName(Application.ExeName)
end;

function TNotificationManager.GetShowSettings: boolean;
begin
  Result := true;
  if HasRegistryRecord then
    if TQuickReg.ValueExists(FRegPath, VALUE_SETTINGS) then
      Result := TQuickReg.GetIntValue(FRegPath, VALUE_SETTINGS) = 1;
end;

function TNotificationManager.HasRegistryRecord: boolean;
begin
  Result := TQuickReg.KeyExists(FRegPath);
end;

procedure TNotificationManager.HideNotification(Notification: TNotification);
begin
  if Notification.Toast = nil then
    raise Exception.Create(NOTIF_BUILD_ERR);

  FNotifier.Hide(Notification.Toast);
end;

procedure TNotificationManager.RebuildNotifier;
var
  AName: HSTRING;
begin
  FNotifier := nil;

  AName := StringToRTString(FAppID);
  FNotifier := TToastNotificationManager.CreateToastNotifier(AName);
  WindowsDeleteString(AName);
end;

procedure TNotificationManager.SetAppActivator(const Value: string);
begin
  CreateRegistryRecord;

  TQuickReg.WriteValue(FRegPath, VALUE_ACTIVATOR, Value);
end;

procedure TNotificationManager.SetAppIcon(const Value: string);
begin
  CreateRegistryRecord;

  // System
  if FIsSystemIcon then
    DeleteIconCache;

  // Set
  if Value <> '' then
    TQuickReg.WriteValue(FRegPath, VALUE_ICON, Value)
  else
    if TQuickReg.ValueExists(FRegPath, VALUE_ICON) then
      TQuickReg.DeleteValue(FRegPath, VALUE_ICON);
end;

procedure TNotificationManager.SetAppID(const Value: string);
var
  PreviousPath: string;
  PreviousRecord: boolean;
begin
  if FAppID = Value then
    Exit;

  // Previous
  PreviousRecord := (FAppID <> '') and HasRegistryRecord;
  PreviousPath := FRegPath;

  // Set
  FAppID := Value;
  FRegPath := FormatRegistry(FAppID);
  RebuildNotifier;

  // Rename
  if PreviousRecord then
    TQuickReg.RenameKey(PreviousPath, FAppID);
end;

procedure TNotificationManager.SetAppLaunch(const Value: string);
begin
  CreateRegistryRecord;

  if Value <> '' then
    TQuickReg.WriteValue(FRegPath, VALUE_LAUNCH, Value)
  else
    if TQuickReg.ValueExists(FRegPath, VALUE_LAUNCH) then
      TQuickReg.DeleteValue(FRegPath, VALUE_LAUNCH);
end;

procedure TNotificationManager.SetAppName(const Value: string);
begin
  CreateRegistryRecord;

  if Value <> '' then
    TQuickReg.WriteValue(FRegPath, VALUE_NAME, Value)
  else
    TQuickReg.WriteValue(FRegPath, VALUE_NAME, GetModuleName);
end;

procedure TNotificationManager.SetGetShowSettings(const Value: boolean);
begin
  CreateRegistryRecord;

  if Value = false then
    TQuickReg.WriteValue(FRegPath, VALUE_SETTINGS, 0)
  else
    if TQuickReg.ValueExists(FRegPath, VALUE_SETTINGS) then
      TQuickReg.DeleteValue(FRegPath, VALUE_SETTINGS);
end;

procedure TNotificationManager.ResetAppIcon;
begin
  SetAppIcon( CreateAppIconCache );
  FIsSystemIcon := true;
end;

procedure TNotificationManager.ShowNotification(Notification: TNotification);
begin
  // Created
  if Notification.Toast = nil then
    raise Exception.Create(NOTIF_BUILD_ERR);

  // Register
  if not HasRegistryRecord then
    CreateRegistryRecord;

  // Show
  FNotifier.Show(Notification.Toast);

  // Status
  Notification.FPosted := true;
end;

{ TNotificationHeader }

function TNotificationHeader.ToXML: string;
begin
  Result := '';

  // Check disabled/invalid
  if (ID = '') or (Title = '') or (Arguments = '') then
    Exit;

  Result := Result + 'id="' + ID + '" ';
  Result := Result + 'title="' + Title + '" ';
  Result := Result + 'arguments="' + Arguments + '" ';

  if ActivationType <> '' then
    Result := Result + 'activationType="' + ActivationType + '" ';

  // Encapsulate
  if Result <> '' then
    Result := EncapsulateXML('header', '', Result);
end;

end.
