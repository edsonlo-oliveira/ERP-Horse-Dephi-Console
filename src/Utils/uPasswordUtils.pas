unit uPasswordUtils;

interface

uses
  System.SysUtils,
  System.Hash,
  System.NetEncoding;

function HashPassword(const APassword: string): string;
function VerifyPassword(const APassword, AStoredHash: string): Boolean;

implementation

const
  PBKDF2_ITERATIONS = 600000;
  SALT_SIZE = 16;
  HASH_SIZE = 32;

function BytesToHex(const ABytes: TBytes): string;
const
  HexChars: array[0..15] of Char =
    '0123456789ABCDEF';
var
  I: Integer;
begin
  SetLength(Result, Length(ABytes) * 2);

  for I := 0 to High(ABytes) do
  begin
    Result[(I * 2) + 1] := HexChars[ABytes[I] shr 4];
    Result[(I * 2) + 2] := HexChars[ABytes[I] and $0F];
  end;
end;

function HexToBytes(const AHex: string): TBytes;
var
  I: Integer;
  Value: Byte;
begin
  if (Length(AHex) mod 2) <> 0 then
    raise EArgumentException.Create('Hexadecimal inválido.');

  SetLength(Result, Length(AHex) div 2);

  for I := 0 to High(Result) do
  begin
    Value := StrToInt('$' +
      Copy(AHex, (I * 2) + 1, 2));

    Result[I] := Value;
  end;
end;

function SecureRandomBytes(ASize: Integer): TBytes;
var
  I: Integer;
begin
  SetLength(Result, ASize);

  for I := 0 to ASize - 1 do
    Result[I] := Random(256);
end;

function HMACSHA256(
  const AData, AKey: TBytes
): TBytes;
begin
  Result := THashSHA2.GetHMACAsBytes(
    AData,
    AKey,
    THashSHA2.TSHA2Version.SHA256
  );
end;

function XorBytes(
  const A, B: TBytes
): TBytes;
var
  I: Integer;
begin
  if Length(A) <> Length(B) then
    raise EArgumentException.Create(
      'Os arrays devem possuir o mesmo tamanho.'
    );

  SetLength(Result, Length(A));

  for I := 0 to High(A) do
    Result[I] := A[I] xor B[I];
end;

function UInt32ToBytes(AValue: Cardinal): TBytes;
begin
  SetLength(Result, 4);

  Result[0] := Byte(AValue shr 24);
  Result[1] := Byte(AValue shr 16);
  Result[2] := Byte(AValue shr 8);
  Result[3] := Byte(AValue);
end;

function PBKDF2(
  const APassword, ASalt: TBytes;
  AIterations, ADerivedKeyLength: Integer
): TBytes;
var
  BlockIndex: Cardinal;
  U: TBytes;
  T: TBytes;
  SaltBlock: TBytes;
  I: Integer;
  Offset: Integer;
begin
  SetLength(Result, 0);

  BlockIndex := 1;

  while Length(Result) < ADerivedKeyLength do
  begin
    SaltBlock :=
      ASalt +
      UInt32ToBytes(BlockIndex);

    U := HMACSHA256(
      SaltBlock,
      APassword
    );

    T := Copy(U, 0, Length(U));

    for I := 2 to AIterations do
    begin
      U := HMACSHA256(
        U,
        APassword
      );

      T := XorBytes(T, U);
    end;

    Offset := Length(Result);

    SetLength(Result,
      Length(Result) + Length(T));

    Move(
      T[0],
      Result[Offset],
      Length(T)
    );

    Inc(BlockIndex);
  end;

  SetLength(Result, ADerivedKeyLength);
end;

function ConstantTimeEquals(
  const A, B: TBytes
): Boolean;
var
  I: Integer;
  Difference: Byte;
begin
  if Length(A) <> Length(B) then
    Exit(False);

  Difference := 0;

  for I := 0 to High(A) do
    Difference := Difference or
      (A[I] xor B[I]);

  Result := Difference = 0;
end;

function HashPassword(
  const APassword: string
): string;
var
  PasswordBytes: TBytes;
  Salt: TBytes;
  DerivedKey: TBytes;
begin
  if APassword = '' then
    raise EArgumentException.Create(
      'A senha não pode estar vazia.'
    );

  PasswordBytes :=
    TEncoding.UTF8.GetBytes(APassword);

  Salt := SecureRandomBytes(SALT_SIZE);

  DerivedKey := PBKDF2(
    PasswordBytes,
    Salt,
    PBKDF2_ITERATIONS,
    HASH_SIZE
  );

  Result :=
    'pbkdf2_sha256$' +
    IntToStr(PBKDF2_ITERATIONS) + '$' +
    BytesToHex(Salt) + '$' +
    BytesToHex(DerivedKey);
end;

function VerifyPassword(
  const APassword, AStoredHash: string
): Boolean;
var
  Parts: TArray<string>;
  Iterations: Integer;
  Salt: TBytes;
  ExpectedHash: TBytes;
  PasswordBytes: TBytes;
  CalculatedHash: TBytes;
begin
  Result := False;

  try
    Parts := AStoredHash.Split(['$']);

    if Length(Parts) <> 4 then
      Exit;

    if Parts[0] <> 'pbkdf2_sha256' then
      Exit;

    Iterations := StrToInt(Parts[1]);

    if Iterations <= 0 then
      Exit;

    Salt := HexToBytes(Parts[2]);
    ExpectedHash := HexToBytes(Parts[3]);

    PasswordBytes :=
      TEncoding.UTF8.GetBytes(APassword);

    CalculatedHash := PBKDF2(
      PasswordBytes,
      Salt,
      Iterations,
      Length(ExpectedHash)
    );

    Result := ConstantTimeEquals(
      CalculatedHash,
      ExpectedHash
    );

  except
    Result := False;
  end;
end;

end.
