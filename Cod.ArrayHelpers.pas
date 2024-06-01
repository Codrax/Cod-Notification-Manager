{***********************************************************}
{                  Codruts Variabile Helpers                }
{                                                           }
{                        version 1.0                        }
{                           ALPHA                           }
{                                                           }
{              https://www.codrutsoft.com/                  }
{             Copyright 2024 Codrut Software                }
{    This unit is licensed for usage under a MIT license    }
{                                                           }
{***********************************************************}

{$SCOPEDENUMS ON}

unit Cod.ArrayHelpers;

interface
  uses
  System.SysUtils, System.Classes,
  System.Generics.Collections, System.Generics.Defaults;

  type
    // TArray colection
    TArrayUtils<T> = class
    private
      type
      TArrayEachCallback = reference to procedure(var Element: T);
      TArrayEachCallbackConst = reference to procedure(Element: T);
      TArrayDualCallback = reference to function(A, B: T): boolean;

    public
      /// <summary> Verify if the array contains element x. </summary>
      class function Contains(const x: T; const Values: TArray<T>): boolean;
      /// <summary> Get the index if element x. </summary>
      class function GetIndex(const x: T; const Values: TArray<T>): integer;
      /// <summary> Go trough all elements of an array and get their value. </summary>
      class procedure ForEach(const Values: TArray<T>; Callback: TArrayEachCallbackConst); overload;
      /// <summary> Go trough all elements of an array and modify their value. </summary>
      class procedure ForEach(var Values: TArray<T>; Callback: TArrayEachCallback); overload;
      /// <summary> Sort the elements of an array using the provided callback for comparison. </summary>
      class procedure Sort(var Values: TArray<T>; Callback: TArrayDualCallback); overload;
      /// <summary> Add value to the end of the array. </summary>
      class function AddValue(const x: T; var Values: TArray<T>) : integer;
      /// <summary> Add value to the end of the array. </summary>
      class procedure AddValues(const Values: TArray<T>; var Destination: TArray<T>);
      /// <summary> Concat secondary array to primary array </summary>
      class function Concat(const Primary, Secondary: TArray<T>) : TArray<T>;
      /// <summary> Insert value at the specified index into the array. </summary>
      class procedure Insert(const Index: integer; const x: T; var Values: TArray<T>);
      /// <summary> Delete element by index from array. </summary>
      class procedure Delete(const Index: integer; var Values: TArray<T>);
      /// <summary> Delete element by type T from array. </summary>
      class procedure DeleteElement(const Element: T; var Values: TArray<T>);
      /// <summary> Set length to specifieed value. </summary>
      class procedure SetLength(const Length: integer; var Values: TArray<T>);
      /// <summary> Get array length. </summary>
      class function Count(const Values: TArray<T>) : integer;
    end;

    // Generic type helpers
    TStringArray = TArray<string>;
    TStringArrayHelper = record helper for TStringArray
    public
      function AddValue(Value: string): integer;
      procedure Insert(Index: integer; Value: string);
      procedure Delete(Index: integer);
      function Count: integer; overload; inline;
      function Find(Value: string): integer;
      procedure SetToLength(ALength: integer);
    end;

    TIntArray = TArray<integer>;
    TIntegerArrayHelper = record helper for TIntArray
    public
      function AddValue(Value: integer): integer;
      procedure Insert(Index: integer; Value: integer);
      procedure Delete(Index: integer);
      function Count: integer; overload; inline;
      function Find(Value: integer): integer;
      procedure SetToLength(ALength: integer);
    end;

    TRealArray = TArray<real>;
    TRealArrayHelper = record helper for TRealArray
    public
      function AddValue(Value: real): integer;
      procedure Insert(Index: integer; Value: real);
      procedure Delete(Index: integer);
      function Count: integer; overload; inline;
      function Find(Value: real): integer;
      procedure SetToLength(ALength: integer);
    end;

    TCharArray = TArray<char>;
    TCharArrayHelper = record helper for TCharArray
    public
      function AddValue(Value: char): integer;
      procedure Insert(Index: integer; Value: char);
      procedure Delete(Index: integer);
      function Count: integer; overload; inline;
      function Find(Value: char): integer;
      procedure SetToLength(ALength: integer);
    end;

    TBoolArray = TArray<boolean>;
    TBoolArrayHelper = record helper for TBoolArray
    public
      function AddValue(Value: boolean): integer;
      procedure Insert(Index: integer; Value: boolean);
      procedure Delete(Index: integer);
      function Count: integer; overload; inline;
      function Find(Value: boolean): integer;  // pretty useless, but can find if a value exists
      procedure SetToLength(ALength: integer);
    end;

implementation

{ TArrayUtils<T> }

class function TArrayUtils<T>.AddValue(const x: T;
  var Values: TArray<T>): integer;
begin
  System.SetLength(Values, length(Values)+1);

  Result := High(Values);
  Values[Result] := x;
end;

class procedure TArrayUtils<T>.AddValues(const Values: TArray<T>;
  var Destination: TArray<T>);
begin
  const StartIndex = High(Destination)+1;
  System.SetLength(Destination, length(Destination)+length(Values));

  const LowPoint = Low(Values);
  for var I := LowPoint to High(Values) do
    Destination[StartIndex+I-LowPoint] := Values[LowPoint];
end;

class function TArrayUtils<T>.Concat(const Primary,
  Secondary: TArray<T>): TArray<T>;
begin
  Result := Primary;

  AddValues(Secondary, Result);
end;

class function TArrayUtils<T>.Contains(const x: T; const Values: TArray<T>): boolean;
var
  y : T;
  lComparer: IEqualityComparer<T>;
begin
  lComparer := TEqualityComparer<T>.Default;
  for y in Values do
  begin
    if lComparer.Equals(x, y) then
      Exit(True);
  end;
  Exit(False);
end;

class function TArrayUtils<T>.Count(const Values: TArray<T>): integer;
begin
  Result := Length(Values);
end;

class procedure TArrayUtils<T>.Delete(const Index: integer;
  var Values: TArray<T>);
begin
  if Index = -1 then
    Exit;

  for var I := Index to High(Values)-1 do
    Values[I] := Values[I+1];

  System.SetLength(Values, 1);
end;

class procedure TArrayUtils<T>.DeleteElement(const Element: T;
  var Values: TArray<T>);
begin
  const Index = GetIndex(Element, Values);
  if Index <> -1 then
    Delete(Index, Values);
end;

class procedure TArrayUtils<T>.ForEach(var Values: TArray<T>;
  Callback: TArrayEachCallback);
begin
  for var I := Low(Values) to High(Values) do
    Callback( Values[I] );
end;

class procedure TArrayUtils<T>.ForEach(const Values: TArray<T>;
  Callback: TArrayEachCallbackConst);
var
  y : T;
  lComparer: IEqualityComparer<T>;
begin
  lComparer := TEqualityComparer<T>.Default;
  for y in Values do
    Callback(y);
end;

class function TArrayUtils<T>.GetIndex(const x: T; const Values: TArray<T>): integer;
var
  I: Integer;
  y: T;
  lComparer: IEqualityComparer<T>;
begin
  lComparer := TEqualityComparer<T>.Default;
  for I := Low(Values) to High(Values) do
    begin
      y := Values[I];

      if lComparer.Equals(x, y) then
        Exit(I);
    end;
    Exit(-1);
end;

class procedure TArrayUtils<T>.Insert(const Index: integer; const x: T;
  var Values: TArray<T>);
var
  Size: integer;
  I: Integer;
begin
  System.SetLength(Values, Length(Values)+1);
  Size := High(Values);

  for I := Size downto Index+1 do
    Values[I] := Values[I-1];
  Values[Index] := x;
end;

class procedure TArrayUtils<T>.SetLength(const Length: integer;
  var Values: TArray<T>);
begin
  System.SetLength(Values, Length);
end;

class procedure TArrayUtils<T>.Sort(var Values: TArray<T>;
  Callback: TArrayDualCallback);
var
  Stack: TArray<Integer >;
  ALow, AHigh, i, j, PivotIndex: Integer;
  Pivot, Temp: T;
begin
  if Length(Values) <= 1 then
    Exit;

  // Initialize the stack for iterative QuickSort
  System.SetLength(Stack, Length(Values) * 2);
  ALow := 0;
  AHigh := High(Values);

  Stack[0] := ALow;
  Stack[1] := AHigh;
  PivotIndex := 2;

  while PivotIndex > 0 do
  begin
    // Pop Low and High from stack
    Dec(PivotIndex);
    AHigh := Stack[PivotIndex];
    Dec(PivotIndex);
    ALow := Stack[PivotIndex];

    // Partition the array
    Pivot := Values[(ALow + AHigh) div 2];
    i := ALow;
    j := AHigh;
    while i <= j do
    begin
      while Callback(Pivot, Values[i]) do
        Inc(i);
      while Callback(Values[j], Pivot) do
        Dec(j);
      if i <= j then
      begin
        Temp := Values[i];
        Values[i] := Values[j];
        Values[j] := Temp;
        Inc(i);
        Dec(j);
      end;
    end;

    // Push sub-arrays onto stack
    if ALow < j then
    begin
      Stack[PivotIndex] := ALow;
      Inc(PivotIndex);
      Stack[PivotIndex] := j;
      Inc(PivotIndex);
    end;
    if i < AHigh then
    begin
      Stack[PivotIndex] := i;
      Inc(PivotIndex);
      Stack[PivotIndex] := AHigh;
      Inc(PivotIndex);
    end;
  end;
end;

// TArray Generic Helpers
function TStringArrayHelper.Count: integer;
begin
  Result := length(Self);
end;

function TIntegerArrayHelper.Count: integer;
begin
  Result := length(Self);
end;

function TRealArrayHelper.Count: integer;
begin
  Result := length(Self);
end;

procedure TStringArrayHelper.SetToLength(ALength: integer);
begin
  SetLength(Self, ALength);
end;

procedure TIntegerArrayHelper.SetToLength(ALength: integer);
begin
  SetLength(Self, ALength);
end;

procedure TRealArrayHelper.SetToLength(ALength: integer);
begin
  SetLength(Self, ALength);
end;

function TStringArrayHelper.AddValue(Value: string): integer;
var
  AIndex: integer;
begin
  AIndex := Length(Self);
  SetLength(Self, AIndex + 1);
  Self[AIndex] := Value;
  Result := AIndex;
end;

function TIntegerArrayHelper.AddValue(Value: integer): integer;
var
  AIndex: integer;
begin
  AIndex := Length(Self);
  SetLength(Self, AIndex + 1);
  Self[AIndex] := Value;
  Result := AIndex;
end;

function TRealArrayHelper.AddValue(Value: real): integer;
var
  AIndex: integer;
begin
  AIndex := Length(Self);
  SetLength(Self, AIndex + 1);
  Self[AIndex] := Value;
  Result := AIndex;
end;

procedure TStringArrayHelper.Insert(Index: integer; Value: string);
var
  Size: integer;
  I: Integer;
begin
  Size := Length(Self);
  SetLength(Self, Size+1);

  for I := Size downto Index+1 do
    Self[I] := Self[I-1];
  Self[Index] := Value;
end;

procedure TIntegerArrayHelper.Insert(Index: integer; Value: integer);
var
  Size: integer;
  I: Integer;
begin
  Size := Length(Self);
  SetLength(Self, Size+1);

  for I := Size downto Index+1 do
    Self[I] := Self[I-1];
  Self[Index] := Value;
end;

procedure TRealArrayHelper.Insert(Index: integer; Value: real);
var
  Size: integer;
  I: Integer;
begin
  Size := Length(Self);
  SetLength(Self, Size+1);

  for I := Size downto Index+1 do
    Self[I] := Self[I-1];
  Self[Index] := Value;
end;

procedure TStringArrayHelper.Delete(Index: integer);
var
  I: Integer;
begin
  if Index <> -1 then
    begin
      for I := Index to High(Self)-1 do
        Self[I] := Self[I+1];

      SetToLength(Length(Self)-1);
    end;
end;

procedure TIntegerArrayHelper.Delete(Index: integer);
var
  I: Integer;
begin
  if Index <> -1 then
    begin
      for I := Index to High(Self)-1 do
        Self[I] := Self[I+1];

      SetToLength(Length(Self)-1);
    end;
end;

procedure TRealArrayHelper.Delete(Index: integer);
var
  I: Integer;
begin
  if Index <> -1 then
    begin
      for I := Index to High(Self)-1 do
        Self[I] := Self[I+1];

      SetToLength(Length(Self)-1);
    end;
end;

function TStringArrayHelper.Find(Value: string): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Low(Self) to High(Self) do
    if Self[I] = Value then
      Exit(I);
end;

function TIntegerArrayHelper.Find(Value: integer): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Low(Self) to High(Self) do
    if Self[I] = Value then
      Exit(I);
end;

function TRealArrayHelper.Find(Value: real): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Low(Self) to High(Self) do
    if Self[I] = Value then
      Exit(I);
end;

{ TBoolArrayHelper }

function TBoolArrayHelper.AddValue(Value: boolean): integer;
var
  AIndex: integer;
begin
  AIndex := Length(Self);
  SetLength(Self, AIndex + 1);
  Self[AIndex] := Value;
  Result := AIndex;
end;

function TBoolArrayHelper.Count: integer;
begin
  Result := length(Self);
end;

procedure TBoolArrayHelper.Delete(Index: integer);
var
  I: Integer;
begin
  if Index <> -1 then
    begin
      for I := Index to High(Self)-1 do
        Self[I] := Self[I+1];

      SetToLength(Length(Self)-1);
    end;
end;

function TBoolArrayHelper.Find(Value: boolean): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Low(Self) to High(Self) do
    if Self[I] = Value then
      Exit(I);
end;

procedure TBoolArrayHelper.Insert(Index: integer; Value: boolean);
var
  Size: integer;
  I: Integer;
begin
  Size := Length(Self);
  SetLength(Self, Size+1);

  for I := Size downto Index+1 do
    Self[I] := Self[I-1];
  Self[Index] := Value;
end;

procedure TBoolArrayHelper.SetToLength(ALength: integer);
begin
  SetLength(Self, ALength);
end;

{ TCharArrayHelper }

function TCharArrayHelper.AddValue(Value: char): integer;
var
  AIndex: integer;
begin
  AIndex := Length(Self);
  SetLength(Self, AIndex + 1);
  Self[AIndex] := Value;
  Result := AIndex;
end;

function TCharArrayHelper.Count: integer;
begin
  Result := length(Self);
end;

procedure TCharArrayHelper.Delete(Index: integer);
var
  I: Integer;
begin
  if Index <> -1 then
    begin
      for I := Index to High(Self)-1 do
        Self[I] := Self[I+1];

      SetToLength(Length(Self)-1);
    end;
end;

function TCharArrayHelper.Find(Value: char): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Low(Self) to High(Self) do
    if Self[I] = Value then
      Exit(I);
end;

procedure TCharArrayHelper.Insert(Index: integer; Value: char);
var
  Size: integer;
  I: Integer;
begin
  Size := Length(Self);
  SetLength(Self, Size+1);

  for I := Size downto Index+1 do
    Self[I] := Self[I-1];
  Self[Index] := Value;
end;

procedure TCharArrayHelper.SetToLength(ALength: integer);
begin
  SetLength(Self, ALength);
end;

end.