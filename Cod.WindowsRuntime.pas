{***********************************************************}
{               Codruts Windows Runtime Utils               }
{                                                           }
{                        version 1.0                        }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{              Copyright 2024 Codrut Software               }
{***********************************************************}

{$SCOPEDENUMS ON}

unit Cod.WindowsRuntime;

interface
  uses
  // System
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, 
  System.Types, Math, Vcl.Forms, IOUtils, System.Generics.Collections, 
  Dialogs, ActiveX, ComObj,

  // Windows RT (Runtime)
  Winapi.Winrt,
  Winapi.Winrt.Utils,
  Winapi.DataRT,
  Winapi.UI.Notifications,

  // Winapi
  Winapi.CommonTypes,
  Winapi.Foundation;

  type
    {$SCOPEDENUMS OFF}
    TWinBoolean = (WinDefault, WinFalse, WinTrue);
    {$SCOPEDENUMS ON}

    TXMLInterface = Xml_Dom_IXmlDocument;

    // WinXML custom document management
    TWinXMLNodes = class;
    TWinXMLAttributes = class;

    TWinXMLNode = class(TObject)
    private
      FTagName: string;
      FParent: TWinXMLNode;

      FContents: string; // content of the node, pre-other nodes
      FNodes: TWinXMLNodes;
      FAttributes: TWinXMLAttributes;
    procedure SetTagName(const Value: string);
    public
      property TagName: string read FTagName write SetTagName;
      property Parent: TWinXMLNode read FParent;

      property Contents: string read FContents write FContents;
      property Nodes: TWinXMLNodes read FNodes write FNodes;
      property Attributes: TWinXMLAttributes read FAttributes write FAttributes;

      // Utils
      procedure Delete;
      procedure Detach;

      // Convert
      function OuterXML: string;
      function InnerXML: string;
      function ToString: string;

      // Constructors
      constructor Create; virtual;
      destructor Destroy; override;
    end;

    TWinXMLAttribute = record
      Tag: string;
      Value: string;
    end;
    TWinXMLNodes = class
    private
      FNodes: TArray<TWinXMLNode>;
      FNodeManager: TWinXMLNode;

      function GetNode(Index: integer): TWinXMLNode;
    public
      function Count: integer;

      // Parent manage
      function DetachNode(Index: integer): boolean; overload;
      function DetachNode(Node: TWinXMLNode): boolean; overload;

      procedure AttachNode(Node: TWinXMLNode); // add existing node clas

      // Manage node
      function FindNode(TagName: string): integer; overload;
      function FindNode(Node: TWinXMLNode): integer; overload;
      function HasNode(TagName: string): boolean;
      function DeleteNode(Index: integer): boolean; overload;
      function DeleteNode(Node: TWinXMLNode): boolean; overload;

      // Create node
      function AddNode(TagName: string): TWinXMLNode; overload;

      procedure Clear;

      property Nodes[Index: integer]: TWinXMLNode read GetNode; default;

      constructor Create(ForNode: TWinXMLNode);
    end;
    TWinXMLAttributes = class
    private
      FAttributes: TArray<TWinXMLAttribute>;

    public
      function Count: integer;

      function FindAttribute(ATag: string): integer;
      function HasAttribute(ATag: string): boolean;
      function DeleteAttribute(Index: integer): boolean; overload;
      function DeleteAttribute(ATag: string): boolean; overload;

      function GetAttribute(Tag: string): string; overload;
      function GetAttribute(Index: integer): string; overload;
      function GetAttributeTag(Index: integer): string;
      procedure SetAttribute(Tag: string; const Value: string);

      property Attributes[Tag: string]: string read GetAttribute write SetAttribute; default;

      constructor Create;
    end;

    TWinXMLDocument = class(TWinXMLNode)
      constructor Create; override;
    end;

    // DomXMLDocument
    TDomXMLDocument = class(TObject)
    public
      DomXML: TXMLInterface;

      // Convert
      procedure Parse(XMLDocument: string);
      function Format: string;

      // Constructors
      constructor Create; overload;
      constructor Create(FromString: string); overload;
      constructor Create(FromInterface: TXMLInterface); overload;
      destructor Destroy; override;
    end;

    // Helpers
    HStringHelper = record helper for HSTRING
      constructor Create(S: string);

      function CompareTo(Value: HString): TValueRelationship;
      function Length: cardinal;
      function Empty: boolean;

      function ToString: string;
      procedure Free;
    end;

  // Utils
  function WinBooleanToString(AType: TWinBoolean): string;
  function StringToHString(Value: string): HSTRING; // Needs to be freed with WindowsDeleteString
  function HStringToString(AString: HSTRING): string;
  procedure FreeHString(AString: HSTRING);
  
  // XML
  function EncapsulateXML(Name: string; Container: string; Tags: string = ''): string;
  function CreateNewXMLInterface: TXMLInterface;

implementation

function WinBooleanToString(AType: TWinBoolean): string;
begin
  case AType of
    TWinBoolean.WinDefault: Result := 'default';
    TWinBoolean.WinFalse: Result := 'false';
    TWinBoolean.WinTrue: Result := 'true';
  end;
end;

function StringToHString(Value: string): HSTRING;
begin            
  if Failed(
    WindowsCreateString(PWideChar(Value), Length(Value), Result)
  ) then 
    raise Exception.CreateFmt('Unable to create HString for %s', [ Value ] );
end;

function HStringToString(AString: HSTRING): string;
var
  buffer: PWideChar;
  length: UINT32;
begin
  buffer := WindowsGetStringRawBuffer(AString, @length);
  if buffer = nil then
    Result := ''
  else
    Result := Copy(buffer, 1, length);
end;

procedure FreeHString(AString: HSTRING);
begin
  if Failed(WindowsDeleteString(AString)) then
    RaiseLastOSError;
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

function CreateNewXMLInterface: TXMLInterface;
var
  instance: IInspectable;
  className: HSTRING;
  xmlDoc: Xml_Dom_IXmlDocument;
  HRes: HRESULT;
begin
  // Initialize output to nil
  xmlDoc := nil;

  // Create the HSTRING for the XmlDocument runtime class name
  className := HSTRING.Create('Windows.Data.Xml.Dom.XmlDocument');

  try
    // Activate the XmlDocument instance
    HRes := RoActivateInstance(className, instance);
    if Failed(HRes) then
      raise Exception.CreateFmt('Failed to activate instance: 0x%.8x', [HRes]);

    // Query for the IXmlDocument interface
    xmlDoc := Xml_Dom_IXmlDocument(instance);
    HRes := instance.QueryInterface(Xml_Dom_IXmlDocument, xmlDoc);
    if Failed(HRes) then
      raise Exception.CreateFmt('Failed to query IXmlDocument interface: 0x%.8x', [HRes]);

    Result := xmlDoc;
  finally
    className.Free;
  end;
end;

{ HStringHelper }

function HStringHelper.CompareTo(Value: HString): TValueRelationship;
begin               
  var O: UINT32;
  if Failed(WindowsCompareStringOrdinal(Self, Value, O)) then
    raise Exception.Create('Comparison failed.');
  Result := O;
end;

constructor HStringHelper.Create(S: string);
begin
  Self := StringToHString(S);
end;

function HStringHelper.Empty: boolean;
begin
  Result := WindowsIsStringEmpty(Self);
end;

procedure HStringHelper.Free;
begin
  FreeHString(Self);
  Self := 0;
end;

function HStringHelper.Length: cardinal;
begin            
  Result := WindowsGetStringLen(Self);
end;

function HStringHelper.ToString: string;
begin
  Result := HStringToString(Self);
end;

{ TDomXMLDocument }

constructor TDomXMLDocument.Create;
begin
  DomXML := CreateNewXMLInterface;
end;

constructor TDomXMLDocument.Create(FromString: string);
begin
  inherited Create;

  Parse( FromString );
end;

constructor TDomXMLDocument.Create(FromInterface: TXMLInterface);
begin
  DomXML := FromInterface;
end;

destructor TDomXMLDocument.Destroy;
begin
  DomXML := nil;

  inherited;
end;

function TDomXMLDocument.Format: string;
var
  HS: HSTRING;
begin
  HS := ( DomXML.DocumentElement as Xml_Dom_IXmlNodeSerializer ).GetXml;
  try
    Result := HS.ToString;
  finally
    HS.Free;
  end;
end;

procedure TDomXMLDocument.Parse(XMLDocument: string);
var
  hXML: HSTRING;
begin
  hXML := HSTRING.Create(XMLDocument);
  try
    (DomXML as Xml_Dom_IXmlDocumentIO).LoadXml( hXML );
  finally
    hXML.Free;
  end;
end;

{ TWinXMLBranch }

constructor TWinXMLNode.Create;
begin
  FTagName := 'node';

  FNodes := TWinXMLNodes.Create(Self);
  FAttributes := TWinXMLAttributes.Create;
end;

procedure TWinXMLNode.Delete;
begin
  if Parent <> nil then
    Parent.Nodes.DeleteNode( Self );
end;

destructor TWinXMLNode.Destroy;
begin
  // Destroy children
  FNodes.Clear;

  inherited;
end;

procedure TWinXMLNode.Detach;
begin
  if Parent <> nil then
    Parent.Nodes.DetachNode( Self );
end;

function TWinXMLNode.InnerXML: string;
begin
  Result := Contents;
  for var I := 0 to Nodes.Count-1 do
    Result := Result + Nodes[I].ToString;
end;

function TWinXMLNode.OuterXML: string;
var
  Attrib, Interior: string;
begin
  // Inner XML
  Interior := InnerXML;

  // Attribute
  Attrib := '';
  for var I := 0 to Attributes.Count-1 do
    Attrib := Format('%S %S="%S"', [Attrib, Attributes.GetAttributeTag(I), Attributes.GetAttribute(I)]);

  // First tag
  if Interior = '' then
    Attrib := Attrib + '/';

  Result := Format('<%S%S>', [TagName, Attrib]);

  // Interior + Closing tag
  if Interior <> '' then
    Result := Result + Interior + Format('</%S>', [TagName]);
end;

procedure TWinXMLNode.SetTagName(const Value: string);
begin
  if Value = '' then
    raise Exception.Create('Tag name cannot be empty.');

  FTagName := Value;
end;

function TWinXMLNode.ToString: string;
begin
  Result := OuterXML;
end;

{ TWinXMLNodes }

function TWinXMLNodes.AddNode(TagName: string): TWinXMLNode;
begin
  Result := TWinXMLNode.Create;
  Result.TagName := TagName;
  AttachNode( Result );
end;

procedure TWinXMLNodes.AttachNode(Node: TWinXMLNode);
begin
  // Detach if attached
  Node.Detach;

  // Allocate space
  const Index = Count;
  SetLength(FNodes, Index+1);
  Node.FParent := FNodeManager;

  // Attach
  FNodes[Index] := Node;
end;

procedure TWinXMLNodes.Clear;
begin
  for var I := Count-1 downto 0 do
    FNodes[I].Free;
  SetLength(FNodes, 0);
end;

function TWinXMLNodes.Count: integer;
begin
  Result := Length(FNodes);
end;

constructor TWinXMLNodes.Create(ForNode: TWinXMLNode);
begin
  FNodeManager := ForNode;
  FNodes := [];
end;

function TWinXMLNodes.DeleteNode(Node: TWinXMLNode): boolean;
begin
  Result := DeleteNode(FindNode(Node));
end;

function TWinXMLNodes.DetachNode(Node: TWinXMLNode): boolean;
begin
  Result := DetachNode(FindNode(Node));
end;

function TWinXMLNodes.DetachNode(Index: integer): boolean;
begin
  Result := InRange(Index, 0, Count-1);
  if not Result then
    Exit;

  FNodes[Index].FParent := nil;
  for var I := Index to Count-2 do
    FNodes[I] := FNodes[I+1];
  SetLength(FNodes, Count-1);
end;

function TWinXMLNodes.FindNode(Node: TWinXMLNode): integer;
begin
  for var I := 0 to High(FNodes) do
    if FNodes[I] = Node then
      Exit(I);

  Exit(-1);
end;

function TWinXMLNodes.DeleteNode(Index: integer): boolean;
begin
  Result := InRange(Index, 0, Count-1);
  if not Result then
    Exit;

  FNodes[Index].Free;
  DetachNode(Index);
end;

function TWinXMLNodes.FindNode(TagName: string): integer;
begin
  for var I := 0 to High(FNodes) do
    if FNodes[I].TagName = TagName then
      Exit(I);

  Exit(-1);
end;

function TWinXMLNodes.GetNode(Index: integer): TWinXMLNode;
begin
  Result := FNodes[Index];
end;

function TWinXMLNodes.HasNode(TagName: string): boolean;
begin
  Result := FindNode(TagName) <> -1;
end;

{ TWinXMLAttributes }

function TWinXMLAttributes.Count: integer;
begin
  Result := Length(FAttributes);
end;

constructor TWinXMLAttributes.Create;
begin
  FAttributes := [];
end;

function TWinXMLAttributes.DeleteAttribute(ATag: string): boolean;
begin
  Result := DeleteAttribute( FindAttribute(ATag) );
end;

function TWinXMLAttributes.DeleteAttribute(Index: integer): boolean;
begin
  Result := InRange(Index, 0, Count-1);
  if not Result then
    Exit;

  for var I := Index to Count-2 do
    FAttributes[I] := FAttributes[I+1];
  SetLength(FAttributes, Count-1);
end;

function TWinXMLAttributes.FindAttribute(ATag: string): integer;
begin
  for var I := 0 to Count-1 do
    if FAttributes[I].Tag = ATag then
      Exit(I);

  Exit(-1);
end;

function TWinXMLAttributes.GetAttribute(Index: integer): string;
begin
  Result := FAttributes[Index].Value;
end;

function TWinXMLAttributes.GetAttributeTag(Index: integer): string;
begin
  Result := FAttributes[Index].Tag;
end;

function TWinXMLAttributes.GetAttribute(Tag: string): string;
begin
  const Index = FindAttribute(Tag);
  Result := FAttributes[index].Value;
end;

function TWinXMLAttributes.HasAttribute(ATag: string): boolean;
begin
  Result := FindAttribute(ATag) <> -1;
end;

procedure TWinXMLAttributes.SetAttribute(Tag: string; const Value: string);
var
  Index: integer;
begin
  // Get Index
  Index := FindAttribute(Tag);
  if Index = -1 then begin
    Index := Count;
    SetLength(FAttributes, Index+1);

    FAttributes[Index].Tag := Tag;
  end;

  // Set
  FAttributes[Index].Value := Value;
end;

{ TWinXMLDocument }

constructor TWinXMLDocument.Create;
begin
  inherited Create;
  FTagName := 'xml';
end;

initialization
  if Failed(RoInitialize(RO_INIT_SINGLETHREADED)) then
    raise Exception.Create('Could not initialize Windows Runtime.');

finalization
  RoUninitialize;
end.
