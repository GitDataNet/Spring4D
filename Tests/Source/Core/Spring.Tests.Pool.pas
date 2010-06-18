{***************************************************************************}
{                                                                           }
{               Generic Number Generator                                    }
{                                                                           }
{               Copyright (C) 2008-2009 Zuo Baoquan                         }
{                                                                           }
{               http://www.zuobaoquan.com (Simplified Chinese)              }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit Spring.Tests.Pool;

interface

uses
  Classes,
  SysUtils,
  TestFramework,
  Spring,
  Spring.Reflection,
  Spring.Pool;

type
  TMockIDObject = class
  private
    fID: Integer;
  public
    constructor Create(id: Integer);
    property ID: Integer read fID;
  end;

  TMockActivator = class(TInterfaceBase, IObjectActivator)
  private
    fLastID: Integer;
  public
    function CreateInstance: TObject;
    property LastID: Integer read fLastID;
  end;

  TTestObjectPool = class(TTestCase)
  private
    fActivator: TMockActivator;
    fPool: IObjectPool;
  protected
    function CreatePool(initialPoolSize, maxPoolSize: Integer): IObjectPool;
    procedure CheckObject(obj: TObject; expectedID: Integer; const msg: string);
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestInitialSizeIsZero;
    procedure TestInitialSizeIsOne;
    procedure TestInitialSizeIsThree;
  end;

implementation

{ TMockActivator }

function TMockActivator.CreateInstance: TObject;
begin
  Inc(fLastID);
  Result := TMockIDObject.Create(fLastID);
end;

{ TMockObject }

constructor TMockIDObject.Create(id: Integer);
begin
  inherited Create;
  fID := id;
end;

{ TTestObjectPool }

procedure TTestObjectPool.SetUp;
begin
  inherited;
  fActivator := TMockActivator.Create;
end;

procedure TTestObjectPool.TearDown;
begin
  fPool := nil;
  FreeAndNil(fActivator);
  inherited TearDown;
end;

function TTestObjectPool.CreatePool(initialPoolSize,
  maxPoolSize: Integer): IObjectPool;
begin
  Result := TSimpleObjectPool.Create(fActivator, initialPoolSize, maxPoolSize);
end;

procedure TTestObjectPool.CheckObject(obj: TObject; expectedID: Integer; const msg: string);
begin
  CheckIs(obj, TMockIDObject, 'obj');
  CheckEquals(expectedID, (obj as TMockIDObject).ID, msg);
end;

procedure TTestObjectPool.TestInitialSizeIsZero;
var
  obj: TObject;
begin
  fPool := CreatePool(0, 0);
  CheckEquals(0, fActivator.LastID, 'LastID should be 0.');

  obj := fPool.GetInstance;
  CheckObject(obj, 1, 'ID should be 1.');
  CheckEquals(1, fActivator.LastID, 'LastID should be 1.');
  fPool.ReleaseInstance(obj);
  CheckEquals(1, fActivator.LastID, 'LastID should be still 1.');
end;

procedure TTestObjectPool.TestInitialSizeIsOne;
var
  obj: TObject;
begin
  fPool := CreatePool(1, 0);
  CheckEquals(1, fActivator.LastID, 'LastID should be 1.');

  obj := fPool.GetInstance;
  CheckObject(obj, 1, 'ID should be 1.');
  fPool.ReleaseInstance(obj);
  CheckEquals(1, fActivator.LastID, 'LastID should be still 1.');

  obj := fPool.GetInstance;
  CheckObject(obj, 1, 'ID should be still 1.');
  CheckEquals(1, fActivator.LastID, 'LastID should be still 1.');

  obj := fPool.GetInstance;
  CheckObject(obj, 2, 'ID should be 2.');
  CheckEquals(2, fActivator.LastID, 'LastID should be 2.');
end;

procedure TTestObjectPool.TestInitialSizeIsThree;
var
  obj: TObject;
begin
  fPool := CreatePool(3, 5);
  CheckEquals(3, fActivator.LastID, 'LastID should be 3.');

  obj := fPool.GetInstance;
  CheckObject(obj, 1, 'ID should be 1.');

  obj := fPool.GetInstance;
  CheckObject(obj, 2, 'ID should be 2.');

  obj := fPool.GetInstance;
  CheckObject(obj, 3, 'ID should be 3.');

  CheckEquals(3, fActivator.LastID, 'LastID should be still 3.');
end;

end.