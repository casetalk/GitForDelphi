unit uGitStatusClasses;

interface

uses
  SysUtils, Classes, Generics.Collections, uGitForDelphi;

type
  // Forward declarations
  TGitRepository = class;
  TGitFolder = class;
  TGitFile = class;

  // Enumeration for Git file status
  TGitFileStatus = (
    gfsUnmodified,      // File is not modified
    gfsModified,        // File is modified in working directory
    gfsAdded,           // File is added to index
    gfsDeleted,         // File is deleted
    gfsRenamed,         // File is renamed
    gfsCopied,          // File is copied
    gfsUntracked,       // File is untracked
    gfsIgnored,         // File is ignored
    gfsConflicted       // File has merge conflicts
  );

  // Set of Git file statuses (a file can have multiple statuses)
  TGitFileStatuses = set of TGitFileStatus;

  // Base class for Git items (files and folders)
  TGitItem = class
  private
    FName: string;
    FPath: string;
    FParent: TGitFolder;
    FRepository: TGitRepository;
  protected
    procedure SetName(const Value: string); virtual;
    procedure SetPath(const Value: string); virtual;
  public
    constructor Create(const AName, APath: string; AParent: TGitFolder; ARepository: TGitRepository);
    destructor Destroy; override;

    property Name: string read FName write SetName;
    property Path: string read FPath write SetPath;
    property Parent: TGitFolder read FParent;
    property Repository: TGitRepository read FRepository;

    function GetFullPath: string; virtual;
    function GetRelativePath: string; virtual;
  end;

  // Class representing a Git-tracked file
  TGitFile = class(TGitItem)
  private
    FStatuses: TGitFileStatuses;
    FSize: Int64;
    FModifiedTime: TDateTime;
    FOid: git_oid;
    FStaged: Boolean;
  protected
    procedure UpdateStatusFromFlags(StatusFlags: Cardinal);
  public
    constructor Create(const AName, APath: string; AParent: TGitFolder; ARepository: TGitRepository);

    property Statuses: TGitFileStatuses read FStatuses write FStatuses;
    property Size: Int64 read FSize write FSize;
    property ModifiedTime: TDateTime read FModifiedTime write FModifiedTime;
    property Oid: git_oid read FOid write FOid;
    property Staged: Boolean read FStaged write FStaged;

    function HasStatus(Status: TGitFileStatus): Boolean;
    function IsModified: Boolean;
    function IsUntracked: Boolean;
    function IsIgnored: Boolean;
    function IsConflicted: Boolean;
    function StatusAsString: string;
    procedure RefreshStatus;
  end;

  // Class representing a folder in Git repository
  TGitFolder = class(TGitItem)
  private
    FFiles: TObjectList<TGitFile>;
    FSubFolders: TObjectList<TGitFolder>;
    FIsRoot: Boolean;
  protected
    function GetFileCount: Integer;
    function GetFolderCount: Integer;
    function GetFile(Index: Integer): TGitFile;
    function GetFolder(Index: Integer): TGitFolder;
  public
    constructor Create(const AName, APath: string; AParent: TGitFolder; ARepository: TGitRepository);
    destructor Destroy; override;

    property Files: TObjectList<TGitFile> read FFiles;
    property SubFolders: TObjectList<TGitFolder> read FSubFolders;
    property IsRoot: Boolean read FIsRoot write FIsRoot;
    property FileCount: Integer read GetFileCount;
    property FolderCount: Integer read GetFolderCount;
    property FileByIndex[Index: Integer]: TGitFile read GetFile;
    property FolderByIndex[Index: Integer]: TGitFolder read GetFolder;

    function FindFile(const FileName: string): TGitFile;
    function FindFolder(const FolderName: string): TGitFolder;
    function AddFile(const FileName: string): TGitFile;
    function AddFolder(const FolderName: string): TGitFolder;
    procedure RemoveFile(const FileName: string); overload;
    procedure RemoveFile(GitFile: TGitFile); overload;
    procedure RemoveFolder(const FolderName: string); overload;
    procedure RemoveFolder(GitFolder: TGitFolder); overload;
    procedure Clear;
    procedure RefreshStatus;

    // Statistics methods
    function GetModifiedFileCount: Integer;
    function GetUntrackedFileCount: Integer;
    function GetStagedFileCount: Integer;
    function GetConflictedFileCount: Integer;

    // Enumeration methods
    procedure EnumerateFiles(Callback: TProc<TGitFile>; Recursive: Boolean = True);
    procedure EnumerateFolders(Callback: TProc<TGitFolder>; Recursive: Boolean = True);
    function GetAllFiles(Recursive: Boolean = True): TArray<TGitFile>;
    function GetAllFolders(Recursive: Boolean = True): TArray<TGitFolder>;
  end;

  // Main Git repository class
  TGitRepository = class
  private
    FRepository: Pgit_repository;
    FRootFolder: TGitFolder;
    FRepositoryPath: string;
    FWorkingDirectory: string;
    FIsOpen: Boolean;
    FIsBare: Boolean;
  protected
    procedure InitializeRootFolder;
    procedure ProcessStatusEntry(const name: PAnsiChar; flags: Cardinal);
  public
    constructor Create;
    destructor Destroy; override;

    property Repository: Pgit_repository read FRepository;
    property RootFolder: TGitFolder read FRootFolder;
    property RepositoryPath: string read FRepositoryPath;
    property WorkingDirectory: string read FWorkingDirectory;
    property IsOpen: Boolean read FIsOpen;
    property IsBare: Boolean read FIsBare;

    function OpenRepository(const Path: string): Boolean;
    function InitRepository(const Path: string; IsBare: Boolean = False): Boolean;
    procedure CloseRepository;

    function RefreshStatus: Boolean;
    function GetStatus(const FilePath: string; out Status: TGitFileStatuses): Boolean;

    // Repository information
    function IsEmpty: Boolean;
    function IsHeadDetached: Boolean;
    function IsHeadOrphan: Boolean;

    // Utility methods
    function GetRelativePath(const FullPath: string): string;
    function GetFullPath(const RelativePath: string): string;
    function IsPathIgnored(const Path: string): Boolean;

    // File operations
    function AddFileToIndex(const FilePath: string): Boolean;
    function RemoveFileFromIndex(const FilePath: string): Boolean;

    // Folder operations
    function CreateFolderStructure(const Path: string): TGitFolder;
    function FindOrCreateFile(const FilePath: string): TGitFile;
  end;

  // Exception classes
  EGitException = class(Exception);
  EGitRepositoryException = class(EGitException);
  EGitFileException = class(EGitException);

implementation

uses
  IOUtils, StrUtils;

// Standalone callback function
function GitStatusCallback(const name: PAnsiChar; flags: Cardinal; payload: PByte): Integer; stdcall;
var
  Repo: TGitRepository;
begin
  Result := 0; // Continue enumeration
  if Assigned(payload) then
  begin
    Repo := TGitRepository(payload);
    Repo.ProcessStatusEntry(name, flags);
  end;
end;

{ TGitItem }

constructor TGitItem.Create(const AName, APath: string; AParent: TGitFolder; ARepository: TGitRepository);
begin
  inherited Create;
  FName := AName;
  FPath := APath;
  FParent := AParent;
  FRepository := ARepository;
end;

destructor TGitItem.Destroy;
begin
  inherited Destroy;
end;

function TGitItem.GetFullPath: string;
begin
  if Assigned(FRepository) then
    Result := TPath.Combine(FRepository.WorkingDirectory, FPath)
  else
    Result := FPath;
end;

function TGitItem.GetRelativePath: string;
begin
  Result := FPath;
end;

procedure TGitItem.SetName(const Value: string);
begin
  FName := Value;
end;

procedure TGitItem.SetPath(const Value: string);
begin
  FPath := Value;
end;

{ TGitFile }

constructor TGitFile.Create(const AName, APath: string; AParent: TGitFolder; ARepository: TGitRepository);
begin
  inherited Create(AName, APath, AParent, ARepository);
  FStatuses := [];
  FSize := 0;
  FModifiedTime := 0;
  FillChar(FOid, SizeOf(FOid), 0);
  FStaged := False;
end;

function TGitFile.HasStatus(Status: TGitFileStatus): Boolean;
begin
  Result := Status in FStatuses;
end;

function TGitFile.IsConflicted: Boolean;
begin
  Result := gfsConflicted in FStatuses;
end;

function TGitFile.IsIgnored: Boolean;
begin
  Result := gfsIgnored in FStatuses;
end;

function TGitFile.IsModified: Boolean;
begin
  Result := gfsModified in FStatuses;
end;

function TGitFile.IsUntracked: Boolean;
begin
  Result := gfsUntracked in FStatuses;
end;

procedure TGitFile.RefreshStatus;
var
  StatusFlags: Cardinal;
  FilePath: PAnsiChar;
  StatusPtr: PCardinal;
begin
  if not Assigned(FRepository) or not FRepository.IsOpen then
    Exit;

  FilePath := PAnsiChar(AnsiString(FPath));
  StatusPtr := @StatusFlags;
  if git_status_file(StatusPtr, FRepository.Repository, FilePath) = GIT_SUCCESS then
    UpdateStatusFromFlags(StatusFlags);
end;

function TGitFile.StatusAsString: string;
var
  StatusList: TStringList;
begin
  StatusList := TStringList.Create;
  try
    if gfsUnmodified in FStatuses then StatusList.Add('Unmodified');
    if gfsModified in FStatuses then StatusList.Add('Modified');
    if gfsAdded in FStatuses then StatusList.Add('Added');
    if gfsDeleted in FStatuses then StatusList.Add('Deleted');
    if gfsRenamed in FStatuses then StatusList.Add('Renamed');
    if gfsCopied in FStatuses then StatusList.Add('Copied');
    if gfsUntracked in FStatuses then StatusList.Add('Untracked');
    if gfsIgnored in FStatuses then StatusList.Add('Ignored');
    if gfsConflicted in FStatuses then StatusList.Add('Conflicted');

    Result := StatusList.CommaText;
  finally
    StatusList.Free;
  end;
end;

procedure TGitFile.UpdateStatusFromFlags(StatusFlags: Cardinal);
begin
  FStatuses := [];

  if StatusFlags = GIT_STATUS_CURRENT then
    Include(FStatuses, gfsUnmodified);

  // Index status
  if (StatusFlags and GIT_STATUS_INDEX_NEW) <> 0 then
    Include(FStatuses, gfsAdded);
  if (StatusFlags and GIT_STATUS_INDEX_MODIFIED) <> 0 then
    Include(FStatuses, gfsModified);
  if (StatusFlags and GIT_STATUS_INDEX_DELETED) <> 0 then
    Include(FStatuses, gfsDeleted);

  // Working tree status
  if (StatusFlags and GIT_STATUS_WT_NEW) <> 0 then
    Include(FStatuses, gfsUntracked);
  if (StatusFlags and GIT_STATUS_WT_MODIFIED) <> 0 then
    Include(FStatuses, gfsModified);
  if (StatusFlags and GIT_STATUS_WT_DELETED) <> 0 then
    Include(FStatuses, gfsDeleted);

  if (StatusFlags and GIT_STATUS_IGNORED) <> 0 then
    Include(FStatuses, gfsIgnored);

  // Check if file is staged
  FStaged := ((StatusFlags and GIT_STATUS_INDEX_NEW) <> 0) or
             ((StatusFlags and GIT_STATUS_INDEX_MODIFIED) <> 0) or
             ((StatusFlags and GIT_STATUS_INDEX_DELETED) <> 0);
end;

{ TGitFolder }

constructor TGitFolder.Create(const AName, APath: string; AParent: TGitFolder; ARepository: TGitRepository);
begin
  inherited Create(AName, APath, AParent, ARepository);
  FFiles := TObjectList<TGitFile>.Create(True);
  FSubFolders := TObjectList<TGitFolder>.Create(True);
  FIsRoot := AParent = nil;
end;

destructor TGitFolder.Destroy;
begin
  FFiles.Free;
  FSubFolders.Free;
  inherited Destroy;
end;

function TGitFolder.AddFile(const FileName: string): TGitFile;
var
  FilePath: string;
begin
  if FPath = '' then
    FilePath := FileName
  else
    FilePath := FPath + '/' + FileName;

  Result := TGitFile.Create(FileName, FilePath, Self, FRepository);
  FFiles.Add(Result);
end;

function TGitFolder.AddFolder(const FolderName: string): TGitFolder;
var
  FolderPath: string;
begin
  if FPath = '' then
    FolderPath := FolderName
  else
    FolderPath := FPath + '/' + FolderName;

  Result := TGitFolder.Create(FolderName, FolderPath, Self, FRepository);
  FSubFolders.Add(Result);
end;

procedure TGitFolder.Clear;
begin
  FFiles.Clear;
  FSubFolders.Clear;
end;

procedure TGitFolder.EnumerateFiles(Callback: TProc<TGitFile>; Recursive: Boolean);
var
  GitFile: TGitFile;
  SubFolder: TGitFolder;
begin
  for GitFile in FFiles do
    Callback(GitFile);

  if Recursive then
  begin
    for SubFolder in FSubFolders do
      SubFolder.EnumerateFiles(Callback, True);
  end;
end;

procedure TGitFolder.EnumerateFolders(Callback: TProc<TGitFolder>; Recursive: Boolean);
var
  SubFolder: TGitFolder;
begin
  for SubFolder in FSubFolders do
  begin
    Callback(SubFolder);
    if Recursive then
      SubFolder.EnumerateFolders(Callback, True);
  end;
end;

function TGitFolder.FindFile(const FileName: string): TGitFile;
var
  GitFile: TGitFile;
begin
  Result := nil;
  for GitFile in FFiles do
  begin
    if SameText(GitFile.Name, FileName) then
    begin
      Result := GitFile;
      Break;
    end;
  end;
end;

function TGitFolder.FindFolder(const FolderName: string): TGitFolder;
var
  SubFolder: TGitFolder;
begin
  Result := nil;
  for SubFolder in FSubFolders do
  begin
    if SameText(SubFolder.Name, FolderName) then
    begin
      Result := SubFolder;
      Break;
    end;
  end;
end;

function TGitFolder.GetAllFiles(Recursive: Boolean): TArray<TGitFile>;
var
  FileList: TList<TGitFile>;
begin
  FileList := TList<TGitFile>.Create;
  try
    EnumerateFiles(
      procedure(GitFile: TGitFile)
      begin
        FileList.Add(GitFile);
      end, Recursive);
    Result := FileList.ToArray;
  finally
    FileList.Free;
  end;
end;

function TGitFolder.GetAllFolders(Recursive: Boolean): TArray<TGitFolder>;
var
  FolderList: TList<TGitFolder>;
begin
  FolderList := TList<TGitFolder>.Create;
  try
    EnumerateFolders(
      procedure(GitFolder: TGitFolder)
      begin
        FolderList.Add(GitFolder);
      end, Recursive);
    Result := FolderList.ToArray;
  finally
    FolderList.Free;
  end;
end;

function TGitFolder.GetConflictedFileCount: Integer;
var
  Count: Integer;
begin
  Count := 0;
  EnumerateFiles(
    procedure(GitFile: TGitFile)
    begin
      if GitFile.IsConflicted then
        Inc(Count);
    end, True);
  Result := Count;
end;

function TGitFolder.GetFile(Index: Integer): TGitFile;
begin
  Result := FFiles[Index];
end;

function TGitFolder.GetFileCount: Integer;
begin
  Result := FFiles.Count;
end;

function TGitFolder.GetFolder(Index: Integer): TGitFolder;
begin
  Result := FSubFolders[Index];
end;

function TGitFolder.GetFolderCount: Integer;
begin
  Result := FSubFolders.Count;
end;

function TGitFolder.GetModifiedFileCount: Integer;
var
  Count: Integer;
begin
  Count := 0;
  EnumerateFiles(
    procedure(GitFile: TGitFile)
    begin
      if GitFile.IsModified then
        Inc(Count);
    end, True);
  Result := Count;
end;

function TGitFolder.GetStagedFileCount: Integer;
var
  Count: Integer;
begin
  Count := 0;
  EnumerateFiles(
    procedure(GitFile: TGitFile)
    begin
      if GitFile.Staged then
        Inc(Count);
    end, True);
  Result := Count;
end;

function TGitFolder.GetUntrackedFileCount: Integer;
var
  Count: Integer;
begin
  Count := 0;
  EnumerateFiles(
    procedure(GitFile: TGitFile)
    begin
      if GitFile.IsUntracked then
        Inc(Count);
    end, True);
  Result := Count;
end;

procedure TGitFolder.RefreshStatus;
var
  GitFile: TGitFile;
  SubFolder: TGitFolder;
begin
  for GitFile in FFiles do
    GitFile.RefreshStatus;

  for SubFolder in FSubFolders do
    SubFolder.RefreshStatus;
end;

procedure TGitFolder.RemoveFile(const FileName: string);
var
  GitFile: TGitFile;
begin
  GitFile := FindFile(FileName);
  if Assigned(GitFile) then
    FFiles.Remove(GitFile);
end;

procedure TGitFolder.RemoveFile(GitFile: TGitFile);
begin
  FFiles.Remove(GitFile);
end;

procedure TGitFolder.RemoveFolder(const FolderName: string);
var
  SubFolder: TGitFolder;
begin
  SubFolder := FindFolder(FolderName);
  if Assigned(SubFolder) then
    FSubFolders.Remove(SubFolder);
end;

procedure TGitFolder.RemoveFolder(GitFolder: TGitFolder);
begin
  FSubFolders.Remove(GitFolder);
end;

{ TGitRepository }

constructor TGitRepository.Create;
begin
  inherited Create;
  FRepository := nil;
  FRootFolder := nil;
  FIsOpen := False;
  FIsBare := False;
end;

destructor TGitRepository.Destroy;
begin
  CloseRepository;
  inherited Destroy;
end;

function TGitRepository.AddFileToIndex(const FilePath: string): Boolean;
var
  Index: Pgit_index;
  RelPath: PAnsiChar;
begin
  Result := False;
  if not FIsOpen then Exit;

  if git_repository_index(Index, FRepository) = GIT_SUCCESS then
  try
    RelPath := PAnsiChar(AnsiString(GetRelativePath(FilePath)));
    Result := git_index_add(Index, RelPath, 0) = GIT_SUCCESS;
    if Result then
      Result := git_index_write(Index) = GIT_SUCCESS;
  finally
    git_index_free(Index);
  end;
end;

procedure TGitRepository.CloseRepository;
begin
  if FIsOpen then
  begin
    FRootFolder.Free;
    FRootFolder := nil;
    git_repository_free(FRepository);
    FRepository := nil;
    FIsOpen := False;
    FRepositoryPath := '';
    FWorkingDirectory := '';
  end;
end;

function TGitRepository.CreateFolderStructure(const Path: string): TGitFolder;
var
  Parts: TArray<string>;
  CurrentFolder: TGitFolder;
  Part: string;
  SubFolder: TGitFolder;
begin
  Result := FRootFolder;
  if Path = '' then Exit;

  Parts := Path.Split(['/']);
  CurrentFolder := FRootFolder;

  for Part in Parts do
  begin
    SubFolder := CurrentFolder.FindFolder(Part);
    if not Assigned(SubFolder) then
      SubFolder := CurrentFolder.AddFolder(Part);
    CurrentFolder := SubFolder;
  end;

  Result := CurrentFolder;
end;

function TGitRepository.FindOrCreateFile(const FilePath: string): TGitFile;
var
  DirPath, FileName: string;
  ParentFolder: TGitFolder;
begin
  DirPath := ExtractFilePath(FilePath);
  FileName := ExtractFileName(FilePath);

  // Remove trailing slash
  if DirPath.EndsWith('/') then
    DirPath := DirPath.Substring(0, DirPath.Length - 1);

  ParentFolder := CreateFolderStructure(DirPath);
  Result := ParentFolder.FindFile(FileName);

  if not Assigned(Result) then
    Result := ParentFolder.AddFile(FileName);
end;

function TGitRepository.GetFullPath(const RelativePath: string): string;
begin
  Result := TPath.Combine(FWorkingDirectory, RelativePath);
end;

function TGitRepository.GetRelativePath(const FullPath: string): string;
begin
  if FullPath.StartsWith(FWorkingDirectory) then
    Result := FullPath.Substring(FWorkingDirectory.Length + 1)
  else
    Result := FullPath;
end;

function TGitRepository.GetStatus(const FilePath: string; out Status: TGitFileStatuses): Boolean;
var
  StatusFlags: Cardinal;
  RelPath: PAnsiChar;
  StatusPtr: PCardinal;
begin
  Result := False;
  Status := [];

  if not FIsOpen then Exit;

  RelPath := PAnsiChar(AnsiString(GetRelativePath(FilePath)));
  StatusPtr := @StatusFlags;
  if git_status_file(StatusPtr, FRepository, RelPath) = GIT_SUCCESS then
  begin
    // Convert status flags to our enum set
    if StatusFlags = GIT_STATUS_CURRENT then
      Include(Status, gfsUnmodified);

    if (StatusFlags and (GIT_STATUS_INDEX_NEW or GIT_STATUS_WT_NEW)) <> 0 then
      Include(Status, gfsAdded);
    if (StatusFlags and (GIT_STATUS_INDEX_MODIFIED or GIT_STATUS_WT_MODIFIED)) <> 0 then
      Include(Status, gfsModified);
    if (StatusFlags and (GIT_STATUS_INDEX_DELETED or GIT_STATUS_WT_DELETED)) <> 0 then
      Include(Status, gfsDeleted);
    if (StatusFlags and GIT_STATUS_WT_NEW) <> 0 then
      Include(Status, gfsUntracked);
    if (StatusFlags and GIT_STATUS_IGNORED) <> 0 then
      Include(Status, gfsIgnored);

    Result := True;
  end;
end;

function TGitRepository.InitRepository(const Path: string; IsBare: Boolean): Boolean;
var
  Repo: Pgit_repository;
begin
  Result := False;

  if not InitLibgit2 then
    raise EGitRepositoryException.Create('Failed to initialize libgit2');

  if git_repository_init(Repo, PAnsiChar(AnsiString(Path)), Ord(IsBare)) = GIT_SUCCESS then
  begin
    CloseRepository; // Close any existing repository

    FRepository := Repo;
    FRepositoryPath := string(PAnsiChar(git_repository_path(FRepository)));
    if not IsBare then
      FWorkingDirectory := string(PAnsiChar(git_repository_workdir(FRepository)))
    else
      FWorkingDirectory := FRepositoryPath;
    FIsOpen := True;
    FIsBare := IsBare;

    InitializeRootFolder;
    Result := True;
  end;
end;

procedure TGitRepository.InitializeRootFolder;
begin
  if Assigned(FRootFolder) then
    FRootFolder.Free;

  FRootFolder := TGitFolder.Create('', '', nil, Self);
  FRootFolder.IsRoot := True;
end;

function TGitRepository.IsEmpty: Boolean;
begin
  Result := False;
  if FIsOpen then
    Result := git_repository_is_empty(FRepository) = 1;
end;

function TGitRepository.IsHeadDetached: Boolean;
begin
  Result := False;
  if FIsOpen then
    Result := git_repository_head_detached(FRepository) = 1;
end;

function TGitRepository.IsHeadOrphan: Boolean;
begin
  Result := False;
  if FIsOpen then
    Result := git_repository_head_orphan(FRepository) = 1;
end;

function TGitRepository.IsPathIgnored(const Path: string): Boolean;
var
  Ignored: Integer;
  RelPath: PAnsiChar;
begin
  Result := False;
  if not FIsOpen then Exit;

  RelPath := PAnsiChar(AnsiString(GetRelativePath(Path)));
  if git_status_should_ignore(FRepository, RelPath, @Ignored) = GIT_SUCCESS then
    Result := Ignored <> 0;
end;

function TGitRepository.OpenRepository(const Path: string): Boolean;
var
  Repo: Pgit_repository;
begin
  Result := False;

  if not InitLibgit2 then
    raise EGitRepositoryException.Create('Failed to initialize libgit2');

  if git_repository_open(Repo, PAnsiChar(AnsiString(Path))) = GIT_SUCCESS then
  begin
    CloseRepository; // Close any existing repository

    FRepository := Repo;
    FRepositoryPath := string(PAnsiChar(git_repository_path(FRepository)));
    FIsBare := git_repository_is_bare(FRepository) = 1;

    if not FIsBare then
      FWorkingDirectory := string(PAnsiChar(git_repository_workdir(FRepository)))
    else
      FWorkingDirectory := FRepositoryPath;

    FIsOpen := True;

    InitializeRootFolder;
    Result := True;
  end;
end;

procedure TGitRepository.ProcessStatusEntry(const name: PAnsiChar; flags: Cardinal);
var
  FilePath: string;
  GitFile: TGitFile;
begin
  FilePath := string(name);
  GitFile := FindOrCreateFile(FilePath);
  GitFile.UpdateStatusFromFlags(flags);
end;

function TGitRepository.RefreshStatus: Boolean;
begin
  Result := False;
  if not FIsOpen then Exit;

  // Clear existing structure
  FRootFolder.Clear;

  // Enumerate all files and their status
  Result := git_status_foreach(FRepository, @GitStatusCallback, PByte(Self)) = GIT_SUCCESS;
end;

function TGitRepository.RemoveFileFromIndex(const FilePath: string): Boolean;
var
  Index: Pgit_index;
  RelPath: PAnsiChar;
  Position: Integer;
begin
  Result := False;
  if not FIsOpen then Exit;

  if git_repository_index(Index, FRepository) = GIT_SUCCESS then
  try
    RelPath := PAnsiChar(AnsiString(GetRelativePath(FilePath)));
    Position := git_index_find(Index, RelPath);
    if Position >= 0 then
    begin
      Result := git_index_remove(Index, Position) = GIT_SUCCESS;
      if Result then
        Result := git_index_write(Index) = GIT_SUCCESS;
    end;
  finally
    git_index_free(Index);
  end;
end;

end.
