unit uGitOperations;

(*

var
  Repo: TGitRepository;
  GitOps: TGitOperations;
begin
  Repo := TGitRepository.Create;
  try
    if Repo.OpenRepository('C:\MyProject') then
    begin
      GitOps := TGitOperations.Create(Repo);
      try
        // Set user info
        GitOps.SetUserInfo('John Doe', 'john@example.com');

        // Stage all modified files
        GitOps.StageAll;

        // Create a commit
        GitOps.CreateCommit('Initial commit');

        // Create a new branch
        GitOps.CreateBranch('feature-branch');

        // Get repository info
        ShowMessage(GitOps.GetRepositoryInfo);

      finally
        GitOps.Free;
      end;
    end;
  finally
    Repo.Free;
  end;
end;

*)

interface

uses
  SysUtils, Classes, uGitForDelphi, uGitStatusClasses;

type
  // Git branch information
  TGitBranchInfo = record
    Name: string;
    IsHead: Boolean;
    IsRemote: Boolean;
    FullName: string;
    Oid: git_oid;
  end;

  // Git commit information
  TGitCommitInfo = record
    Oid: git_oid;
    ShortOid: string;
    Message: string;
    Author: git_signature;
    Committer: git_signature;
    DateTime: TDateTime;
    ParentCount: Integer;
  end;

  // Git remote information
  TGitRemoteInfo = record
    Name: string;
    Url: string;
    FetchSpec: string;
    PushSpec: string;
  end;

  // Git diff statistics
  TGitDiffStats = record
    FilesChanged: Integer;
    Insertions: Integer;
    Deletions: Integer;
  end;

  // Extension class for Git operations
  TGitOperations = class
  private
    FRepository: TGitRepository;
    function CreateSignature(const Name, Email: string): Pgit_signature;
    function GetCurrentBranchName: string;
  public
    constructor Create(ARepository: TGitRepository);
    destructor Destroy; override;

    property Repository: TGitRepository read FRepository;

    // Staging operations
    function StageFile(const FilePath: string): Boolean;
    function StageFiles(const FilePaths: TArray<string>): Boolean;
    function UnstageFile(const FilePath: string): Boolean;
    function UnstageFiles(const FilePaths: TArray<string>): Boolean;
    function StageAll: Boolean;
    function UnstageAll: Boolean;

    // Commit operations
    function CreateCommit(const Message: string; const AuthorName: string = '';
      const AuthorEmail: string = ''): Boolean; overload;
    function CreateCommit(const Message: string; Author, Committer: Pgit_signature): Boolean; overload;
    function AmendLastCommit(const NewMessage: string): Boolean;

    // Branch operations
    function CreateBranch(const BranchName: string; const StartPoint: string = ''): Boolean;
    function DeleteBranch(const BranchName: string; Force: Boolean = False): Boolean;
    function SwitchBranch(const BranchName: string): Boolean;
    function RenameBranch(const OldName, NewName: string): Boolean;
    function GetCurrentBranch: string;
    function GetBranches: TArray<TGitBranchInfo>;
    function BranchExists(const BranchName: string): Boolean;

    // Remote operations
    function AddRemote(const Name, Url: string): Boolean;
    function RemoveRemote(const Name: string): Boolean;
    function GetRemotes: TArray<TGitRemoteInfo>;
    function FetchFromRemote(const RemoteName: string = 'origin'): Boolean;
    function PushToRemote(const RemoteName: string = 'origin'; const BranchName: string = ''): Boolean;
    function PullFromRemote(const RemoteName: string = 'origin'): Boolean;

    // History operations
    function GetCommitHistory(MaxCount: Integer = 100): TArray<TGitCommitInfo>;
    function GetCommit(const OidStr: string): TGitCommitInfo;
    function GetLastCommit: TGitCommitInfo;

    // Reset operations
    function ResetSoft(const Target: string): Boolean;
    function ResetMixed(const Target: string): Boolean;
    function ResetHard(const Target: string): Boolean;

    // Tag operations
    function CreateTag(const TagName, Message: string; const Target: string = ''): Boolean;
    function DeleteTag(const TagName: string): Boolean;
    function GetTags: TArray<string>;

    // Utility operations
    function CheckoutFile(const FilePath: string): Boolean;
    function CheckoutFiles(const FilePaths: TArray<string>): Boolean;
    function DiscardChanges(const FilePath: string): Boolean;
    function DiscardAllChanges: Boolean;
    function CleanWorkingDirectory(RemoveUntrackedFiles: Boolean = True): Boolean;

    // Diff operations
    function GetFileChanges(const FilePath: string): string;
    function GetStagedChanges: string;
    function GetUnstagedChanges: string;
    function GetDiffStats: TGitDiffStats;

    // Configuration operations
    function SetConfig(const Key, Value: string; Global: Boolean = False): Boolean;
    function GetConfig(const Key: string; Global: Boolean = False): string;
    function SetUserInfo(const Name, Email: string; Global: Boolean = True): Boolean;
    function GetUserInfo(out Name, Email: string; Global: Boolean = True): Boolean;

    // Repository information
    function GetRepositoryInfo: string;
    function IsWorkingDirectoryClean: Boolean;
    function HasStagedChanges: Boolean;
    function HasUnstagedChanges: Boolean;
    function GetCurrentCommitOid: string;
    function GetHeadReference: string;

    // Error handling
    function GetLastGitError: string;
    procedure ClearGitError;
  end;

  // Exception classes for Git operations
  EGitOperationException = class(EGitException);
  EGitCommitException = class(EGitOperationException);
  EGitBranchException = class(EGitOperationException);
  EGitRemoteException = class(EGitOperationException);

implementation

uses
  StrUtils, DateUtils;

{ TGitOperations }

constructor TGitOperations.Create(ARepository: TGitRepository);
begin
  inherited Create;
  FRepository := ARepository;
  if not Assigned(FRepository) then
    raise EGitOperationException.Create('Repository cannot be nil');
  if not FRepository.IsOpen then
    raise EGitOperationException.Create('Repository must be open');
end;

destructor TGitOperations.Destroy;
begin
  inherited Destroy;
end;

function TGitOperations.DiscardAllChanges: Boolean;
begin

end;

function TGitOperations.DiscardChanges(const FilePath: string): Boolean;
begin

end;

function TGitOperations.FetchFromRemote(const RemoteName: string): Boolean;
begin

end;

function TGitOperations.StageFile(const FilePath: string): Boolean;
begin
  Result := FRepository.AddFileToIndex(FilePath);
end;

function TGitOperations.StageFiles(const FilePaths: TArray<string>): Boolean;
var
  FilePath: string;
begin
  Result := True;
  for FilePath in FilePaths do
  begin
    if not StageFile(FilePath) then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function TGitOperations.UnstageFile(const FilePath: string): Boolean;
begin
  Result := FRepository.RemoveFileFromIndex(FilePath);
end;

function TGitOperations.UnstageFiles(const FilePaths: TArray<string>): Boolean;
var
  FilePath: string;
begin
  Result := True;
  for FilePath in FilePaths do
  begin
    if not UnstageFile(FilePath) then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function TGitOperations.SetConfig(const Key, Value: string; Global: Boolean): Boolean;
begin

end;

function TGitOperations.SetUserInfo(const Name, Email: string; Global: Boolean): Boolean;
begin

end;

function TGitOperations.StageAll: Boolean;
var
  Index: Pgit_index;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  if git_repository_index(Index, FRepository.Repository) = GIT_SUCCESS then
  try
    // Stage all modified files
    FRepository.RootFolder.EnumerateFiles(
      procedure(GitFile: TGitFile)
      begin
        if GitFile.IsModified or GitFile.IsUntracked then
          StageFile(GitFile.Path);
      end, True);
    Result := True;
  finally
    git_index_free(Index);
  end;
end;

function TGitOperations.UnstageAll: Boolean;
var
  Index: Pgit_index;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  if git_repository_index(Index, FRepository.Repository) = GIT_SUCCESS then
  try
    git_index_clear(Index);
    Result := git_index_write(Index) = GIT_SUCCESS;
  finally
    git_index_free(Index);
  end;
end;

function TGitOperations.CreateSignature(const Name, Email: string): Pgit_signature;
begin
  Result := nil;
  if (Name <> '') and (Email <> '') then
    git_signature_now(Result, PAnsiChar(AnsiString(Name)), PAnsiChar(AnsiString(Email)))
  else
  begin
    // Try to get user info from config
    var UserName, UserEmail: string;
    if GetUserInfo(UserName, UserEmail) then
      git_signature_now(Result, PAnsiChar(AnsiString(UserName)), PAnsiChar(AnsiString(UserEmail)));
  end;
end;

function TGitOperations.CreateTag(const TagName, Message, Target: string): Boolean;
begin

end;

function TGitOperations.CreateCommit(const Message, AuthorName, AuthorEmail: string): Boolean;
var
  Author, Committer: Pgit_signature;
begin
  Author := CreateSignature(AuthorName, AuthorEmail);
  Committer := CreateSignature(AuthorName, AuthorEmail);
  try
    Result := CreateCommit(Message, Author, Committer);
  finally
    if Assigned(Author) then git_signature_free(Author);
    if Assigned(Committer) then git_signature_free(Committer);
  end;
end;

function TGitOperations.CreateCommit(const Message: string; Author, Committer: Pgit_signature): Boolean;
var
  Index: Pgit_index;
  Tree: Pgit_tree;
  TreeOid: git_oid;
  CommitOid: git_oid;
  Head: Pgit_reference;
  Parent: Pgit_commit;
  Parents: array[0..0] of Pgit_commit;
  ParentCount: Integer;
begin
  Result := False;
  if not FRepository.IsOpen or not Assigned(Author) or not Assigned(Committer) then Exit;

  // Get the index and create tree from it
  if git_repository_index(Index, FRepository.Repository) <> GIT_SUCCESS then Exit;
  try
    if git_tree_create_fromindex(@TreeOid, Index) <> GIT_SUCCESS then Exit;
    if git_tree_lookup(Tree, FRepository.Repository, @TreeOid) <> GIT_SUCCESS then Exit;
    try
      // Try to get HEAD reference for parent commit
      ParentCount := 0;
      if git_repository_head(Head, FRepository.Repository) = GIT_SUCCESS then
      try
        if git_reference_oid(Head) <> nil then
        begin
          if git_commit_lookup(Parent, FRepository.Repository, git_reference_oid(Head)) = GIT_SUCCESS then
          begin
            Parents[0] := Parent;
            ParentCount := 1;
          end;
        end;
      finally
        git_reference_free(Head);
      end;

      // Create the commit
      Result := git_commit_create(@CommitOid, FRepository.Repository,
        PAnsiChar('HEAD'), Author, Committer, nil, PAnsiChar(AnsiString(Message)),
        Tree, ParentCount, @Parents[0]) = GIT_SUCCESS;

      if (ParentCount > 0) and Assigned(Parent) then
        git_commit_free(Parent);
    finally
      git_tree_free(Tree);
    end;
  finally
    git_index_free(Index);
  end;
end;

function TGitOperations.AddRemote(const Name, Url: string): Boolean;
begin

end;

function TGitOperations.AmendLastCommit(const NewMessage: string): Boolean;
begin
  // This is a simplified implementation
  // In practice, you'd need to get the last commit, modify it, and create a new commit
  Result := False;
  // Implementation would require more complex logic
end;

function TGitOperations.CreateBranch(const BranchName, StartPoint: string): Boolean;
var
  Branch: Pgit_reference;
  StartCommit: Pgit_commit;
  StartOid: git_oid;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  try
    // If no start point specified, use HEAD
    if StartPoint = '' then
    begin
      var Head: Pgit_reference;
      if git_repository_head(Head, FRepository.Repository) = GIT_SUCCESS then
      try
        if git_commit_lookup(StartCommit, FRepository.Repository, git_reference_oid(Head)) = GIT_SUCCESS then
        begin
          Result := git_reference_create_oid(Branch, FRepository.Repository,
            PAnsiChar(AnsiString('refs/heads/' + BranchName)), git_commit_id(StartCommit), 0) = GIT_SUCCESS;
        end;
      finally
        git_reference_free(Head);
      end;
    end
    else
    begin
      // Parse start point and create branch from there
      if git_oid_fromstr(@StartOid, PAnsiChar(AnsiString(StartPoint))) = GIT_SUCCESS then
      begin
        if git_commit_lookup(StartCommit, FRepository.Repository, @StartOid) = GIT_SUCCESS then
        begin
          Result := git_reference_create_oid(Branch, FRepository.Repository,
            PAnsiChar(AnsiString('refs/heads/' + BranchName)), @StartOid, 0) = GIT_SUCCESS;
        end;
      end;
    end;

    if Result and Assigned(Branch) then
      git_reference_free(Branch);
    if Assigned(StartCommit) then
      git_commit_free(StartCommit);
  except
    Result := False;
  end;
end;

function TGitOperations.DeleteBranch(const BranchName: string; Force: Boolean): Boolean;
var
  Branch: Pgit_reference;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  if git_reference_lookup(Branch, FRepository.Repository,
    PAnsiChar(AnsiString('refs/heads/' + BranchName))) = GIT_SUCCESS then
  try
    Result := git_reference_delete(Branch) = GIT_SUCCESS;
  finally
    git_reference_free(Branch);
  end;
end;

function TGitOperations.DeleteTag(const TagName: string): Boolean;
begin

end;

function TGitOperations.SwitchBranch(const BranchName: string): Boolean;
begin
  Result := False;
  // Implementation would require checkout functionality
  // This is a complex operation that would need proper implementation
end;

function TGitOperations.RemoveRemote(const Name: string): Boolean;
begin

end;

function TGitOperations.RenameBranch(const OldName, NewName: string): Boolean;
var
  Branch: Pgit_reference;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  if git_reference_lookup(Branch, FRepository.Repository,
    PAnsiChar(AnsiString('refs/heads/' + OldName))) = GIT_SUCCESS then
  try
    Result := git_reference_rename(Branch, PAnsiChar(AnsiString('refs/heads/' + NewName)), 0) = GIT_SUCCESS;
  finally
    git_reference_free(Branch);
  end;
end;

function TGitOperations.GetRemotes: TArray<TGitRemoteInfo>;
begin

end;

function TGitOperations.ResetHard(const Target: string): Boolean;
begin

end;

function TGitOperations.ResetMixed(const Target: string): Boolean;
begin

end;

function TGitOperations.ResetSoft(const Target: string): Boolean;
begin

end;

function TGitOperations.GetRepositoryInfo: string;
var
  Info: TStringList;
  CurrentBranch: string;
  LastCommit: TGitCommitInfo;
begin
  Info := TStringList.Create;
  try
    Info.Add('Repository Information:');
    Info.Add('----------------------');
    Info.Add('Path: ' + FRepository.RepositoryPath);
    Info.Add('Working Directory: ' + FRepository.WorkingDirectory);
    Info.Add('Is Bare: ' + BoolToStr(FRepository.IsBare, True));
    Info.Add('Is Empty: ' + BoolToStr(FRepository.IsEmpty, True));
    Info.Add('Head Detached: ' + BoolToStr(FRepository.IsHeadDetached, True));
    Info.Add('Head Orphan: ' + BoolToStr(FRepository.IsHeadOrphan, True));

    CurrentBranch := GetCurrentBranch;
    if CurrentBranch <> '' then
      Info.Add('Current Branch: ' + CurrentBranch);

    LastCommit := GetLastCommit;
    if LastCommit.Message <> '' then
    begin
      Info.Add('Last Commit: ' + LastCommit.ShortOid);
      Info.Add('Last Commit Message: ' + LastCommit.Message);
      Info.Add('Last Commit Date: ' + DateTimeToStr(LastCommit.DateTime));
    end;

    Info.Add('Working Directory Clean: ' + BoolToStr(IsWorkingDirectoryClean, True));
    Info.Add('Has Staged Changes: ' + BoolToStr(HasStagedChanges, True));
    Info.Add('Has Unstaged Changes: ' + BoolToStr(HasUnstagedChanges, True));

    // File counts
    Info.Add('Modified Files: ' + IntToStr(FRepository.RootFolder.GetModifiedFileCount));
    Info.Add('Untracked Files: ' + IntToStr(FRepository.RootFolder.GetUntrackedFileCount));
    Info.Add('Staged Files: ' + IntToStr(FRepository.RootFolder.GetStagedFileCount));
    Info.Add('Conflicted Files: ' + IntToStr(FRepository.RootFolder.GetConflictedFileCount));

    Result := Info.Text;
  finally
    Info.Free;
  end;
end;

function TGitOperations.GetStagedChanges: string;
begin

end;

function TGitOperations.GetTags: TArray<string>;
begin

end;

function TGitOperations.GetUnstagedChanges: string;
begin

end;

function TGitOperations.GetUserInfo(out Name, Email: string; Global: Boolean): Boolean;
begin

end;

function TGitOperations.IsWorkingDirectoryClean: Boolean;
begin
  Result := not HasStagedChanges and not HasUnstagedChanges;
end;

function TGitOperations.PullFromRemote(const RemoteName: string): Boolean;
begin

end;

function TGitOperations.PushToRemote(const RemoteName, BranchName: string): Boolean;
begin

end;

function TGitOperations.HasStagedChanges: Boolean;
begin
  Result := FRepository.RootFolder.GetStagedFileCount > 0;
end;

function TGitOperations.HasUnstagedChanges: Boolean;
begin
  Result := (FRepository.RootFolder.GetModifiedFileCount > 0) or
            (FRepository.RootFolder.GetUntrackedFileCount > 0);
end;

function TGitOperations.GetBranches: TArray<TGitBranchInfo>;
begin

end;

function TGitOperations.GetCommit(const OidStr: string): TGitCommitInfo;
begin

end;

function TGitOperations.GetCommitHistory(MaxCount: Integer): TArray<TGitCommitInfo>;
begin

end;

function TGitOperations.GetConfig(const Key: string; Global: Boolean): string;
begin

end;

function TGitOperations.GetCurrentBranch: string;
begin

end;

function TGitOperations.GetCurrentBranchName: string;
begin

end;

function TGitOperations.GetCurrentCommitOid: string;
var
  Head: Pgit_reference;
begin
  Result := '';
  if not FRepository.IsOpen then Exit;

  if git_repository_head(Head, FRepository.Repository) = GIT_SUCCESS then
  try
    Result := git_oid_to_string(nil, 41, git_reference_oid(Head));
  finally
    git_reference_free(Head);
  end;
end;

function TGitOperations.GetDiffStats: TGitDiffStats;
begin

end;

function TGitOperations.GetFileChanges(const FilePath: string): string;
begin

end;

function TGitOperations.GetHeadReference: string;
var
  Head: Pgit_reference;
begin
  Result := '';
  if not FRepository.IsOpen then Exit;

  if git_repository_head(Head, FRepository.Repository) = GIT_SUCCESS then
  try
    Result := string(PAnsiChar(git_reference_name(Head)));
  finally
    git_reference_free(Head);
  end;
end;

function TGitOperations.GetLastCommit: TGitCommitInfo;
begin

end;

function TGitOperations.GetLastGitError: string;
begin
  Result := string(PAnsiChar(git_lasterror));
end;

function TGitOperations.BranchExists(const BranchName: string): Boolean;
begin

end;

function TGitOperations.CheckoutFile(const FilePath: string): Boolean;
begin

end;

function TGitOperations.CheckoutFiles(const FilePaths: TArray<string>): Boolean;
begin

end;

function TGitOperations.CleanWorkingDirectory(RemoveUntrackedFiles: Boolean): Boolean;
begin

end;

procedure TGitOperations.ClearGitError;
begin
  git_clearerror;
end;

end.CurrentBranch: string;
var
  Head: Pgit_reference;
  HeadPtr: PPgit_reference;
begin
  Result := '';
  if not FRepository.IsOpen then Exit;

  HeadPtr := @Head;
  if git_repository_head(HeadPtr, FRepository.Repository) = GIT_SUCCESS then
  try
    Result := string(PAnsiChar(git_reference_name(Head)));
    // Remove 'refs/heads/' prefix
    if Result.StartsWith('refs/heads/') then
      Result := Result.Substring(11);
  finally
    git_reference_free(Head);
  end;
end;

function TGitOperations.GetCurrentBranchName: string;
begin
  Result := GetCurrentBranch;
end;

function TGitOperations.GetBranches: TArray<TGitBranchInfo>;
begin
  // Implementation would require iterating through references
  SetLength(Result, 0);
end;

function TGitOperations.BranchExists(const BranchName: string): Boolean;
var
  Branch: Pgit_reference;
  BranchPtr: PPgit_reference;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  BranchPtr := @Branch;
  if git_reference_lookup(BranchPtr, FRepository.Repository,
    PAnsiChar(AnsiString('refs/heads/' + BranchName))) = GIT_SUCCESS then
  begin
    Result := True;
    git_reference_free(Branch);
  end;
end;

function TGitOperations.AddRemote(const Name, Url: string): Boolean;
var
  Remote: Pgit_remote;
  RemotePtr: PPgit_remote;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  RemotePtr := @Remote;
  if git_remote_new(RemotePtr, FRepository.Repository,
    PAnsiChar(AnsiString(Url)), PAnsiChar(AnsiString(Name))) = GIT_SUCCESS then
  begin
    Result := True;
    git_remote_free(Remote);
  end;
end;

function TGitOperations.RemoveRemote(const Name: string): Boolean;
begin
  Result := False;
  // Implementation would require remote management functions
end;

function TGitOperations.GetRemotes: TArray<TGitRemoteInfo>;
begin
  // Implementation would require iterating through remotes
  SetLength(Result, 0);
end;

function TGitOperations.FetchFromRemote(const RemoteName: string): Boolean;
var
  Remote: Pgit_remote;
  RemotePtr: PPgit_remote;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  RemotePtr := @Remote;
  if git_remote_load(RemotePtr, FRepository.Repository, PAnsiChar(AnsiString(RemoteName))) = GIT_SUCCESS then
  try
    if git_remote_connect(Remote, GIT_DIR_FETCH) = GIT_SUCCESS then
    begin
      // Fetch implementation would go here
      Result := True;
      git_remote_disconnect(Remote);
    end;
  finally
    git_remote_free(Remote);
  end;
end;

function TGitOperations.PushToRemote(const RemoteName, BranchName: string): Boolean;
begin
  Result := False;
  // Implementation would require push functionality
end;

function TGitOperations.PullFromRemote(const RemoteName: string): Boolean;
begin
  Result := False;
  // Implementation would require merge functionality after fetch
end;

function TGitOperations.GetCommitHistory(MaxCount: Integer): TArray<TGitCommitInfo>;
var
  Walker: Pgit_revwalk;
  CommitOid: git_oid;
  Commit: Pgit_commit;
  CommitList: TList<TGitCommitInfo>;
  CommitInfo: TGitCommitInfo;
  Count: Integer;
  WalkerPtr: PPgit_revwalk;
  CommitPtr: PPgit_commit;
begin
  SetLength(Result, 0);
  if not FRepository.IsOpen then Exit;

  CommitList := TList<TGitCommitInfo>.Create;
  try
    WalkerPtr := @Walker;
    CommitPtr := @Commit;

    if git_revwalk_new(WalkerPtr, FRepository.Repository) = GIT_SUCCESS then
    try
      git_revwalk_sorting(Walker, GIT_SORT_TIME);

      // Push HEAD
      var Head: Pgit_reference;
      var HeadPtr: PPgit_reference := @Head;
      if git_repository_head(HeadPtr, FRepository.Repository) = GIT_SUCCESS then
      try
        git_revwalk_push(Walker, git_reference_oid(Head));
      finally
        git_reference_free(Head);
      end;

      Count := 0;
      while (git_revwalk_next(@CommitOid, Walker) = GIT_SUCCESS) and (Count < MaxCount) do
      begin
        if git_commit_lookup(CommitPtr, FRepository.Repository, @CommitOid) = GIT_SUCCESS then
        try
          FillChar(CommitInfo, SizeOf(CommitInfo), 0);
          CommitInfo.Oid := CommitOid;
          CommitInfo.ShortOid := Copy(git_oid_to_string(nil, 41, @CommitOid), 1, 8);
          CommitInfo.Message := string(PAnsiChar(git_commit_message(Commit)));
          CommitInfo.Author := git_commit_author(Commit)^;
          CommitInfo.Committer := git_commit_committer(Commit)^;
          CommitInfo.DateTime := time_t__to__TDateTime(git_commit_time(Commit), git_commit_time_offset(Commit));
          CommitInfo.ParentCount := git_commit_parentcount(Commit);

          CommitList.Add(CommitInfo);
          Inc(Count);
        finally
          git_commit_free(Commit);
        end;
      end;
    finally
      git_revwalk_free(Walker);
    end;

    Result := CommitList.ToArray;
  finally
    CommitList.Free;
  end;
end;

function TGitOperations.GetCommit(const OidStr: string): TGitCommitInfo;
var
  Oid: git_oid;
  Commit: Pgit_commit;
  CommitPtr: PPgit_commit;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FRepository.IsOpen then Exit;

  CommitPtr := @Commit;
  if git_oid_fromstr(@Oid, PAnsiChar(AnsiString(OidStr))) = GIT_SUCCESS then
  begin
    if git_commit_lookup(CommitPtr, FRepository.Repository, @Oid) = GIT_SUCCESS then
    try
      Result.Oid := Oid;
      Result.ShortOid := Copy(OidStr, 1, 8);
      Result.Message := string(PAnsiChar(git_commit_message(Commit)));
      Result.Author := git_commit_author(Commit)^;
      Result.Committer := git_commit_committer(Commit)^;
      Result.DateTime := time_t__to__TDateTime(git_commit_time(Commit), git_commit_time_offset(Commit));
      Result.ParentCount := git_commit_parentcount(Commit);
    finally
      git_commit_free(Commit);
    end;
  end;
end;

function TGitOperations.GetLastCommit: TGitCommitInfo;
var
  Head: Pgit_reference;
  HeadPtr: PPgit_reference;
  OidStr: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FRepository.IsOpen then Exit;

  HeadPtr := @Head;
  if git_repository_head(HeadPtr, FRepository.Repository) = GIT_SUCCESS then
  try
    OidStr := git_oid_to_string(nil, 41, git_reference_oid(Head));
    Result := GetCommit(OidStr);
  finally
    git_reference_free(Head);
  end;
end;

function TGitOperations.ResetSoft(const Target: string): Boolean;
begin
  Result := False;
  // Implementation would require reset functionality
end;

function TGitOperations.ResetMixed(const Target: string): Boolean;
begin
  Result := False;
  // Implementation would require reset functionality
end;

function TGitOperations.ResetHard(const Target: string): Boolean;
begin
  Result := False;
  // Implementation would require reset functionality
end;

function TGitOperations.CreateTag(const TagName, Message, Target: string): Boolean;
var
  TagOid: git_oid;
  TargetCommit: Pgit_commit;
  Author: Pgit_signature;
  CommitPtr: PPgit_commit;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  CommitPtr := @TargetCommit;
  Author := CreateSignature('', '');
  try
    // If no target specified, use HEAD
    if Target = '' then
    begin
      var Head: Pgit_reference;
      var HeadPtr: PPgit_reference := @Head;
      if git_repository_head(HeadPtr, FRepository.Repository) = GIT_SUCCESS then
      try
        if git_commit_lookup(CommitPtr, FRepository.Repository, git_reference_oid(Head)) = GIT_SUCCESS then
        begin
          Result := git_tag_create(@TagOid, FRepository.Repository,
            PAnsiChar(AnsiString(TagName)), Pgit_object(TargetCommit), Author,
            PAnsiChar(AnsiString(Message)), 0) = GIT_SUCCESS;
        end;
      finally
        git_reference_free(Head);
      end;
    end;

    if Assigned(TargetCommit) then
      git_commit_free(TargetCommit);
  finally
    if Assigned(Author) then
      git_signature_free(Author);
  end;
end;

function TGitOperations.DeleteTag(const TagName: string): Boolean;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  Result := git_tag_delete(FRepository.Repository, PAnsiChar(AnsiString(TagName))) = GIT_SUCCESS;
end;

function TGitOperations.GetTags: TArray<string>;
var
  TagNames: git_strarray;
begin
  SetLength(Result, 0);
  if not FRepository.IsOpen then Exit;

  if git_tag_list(@TagNames, FRepository.Repository) = GIT_SUCCESS then
  try
    SetLength(Result, TagNames.count);
    for var i := 0 to TagNames.count - 1 do
    begin
      Result[i] := string(PAnsiChar(TagNames.strings[i]));
    end;
  finally
    git_strarray_free(@TagNames);
  end;
end;

function TGitOperations.CheckoutFile(const FilePath: string): Boolean;
begin
  Result := False;
  // Implementation would require checkout functionality
end;

function TGitOperations.CheckoutFiles(const FilePaths: TArray<string>): Boolean;
begin
  Result := False;
  // Implementation would require checkout functionality
end;

function TGitOperations.DiscardChanges(const FilePath: string): Boolean;
begin
  Result := CheckoutFile(FilePath);
end;

function TGitOperations.DiscardAllChanges: Boolean;
begin
  Result := False;
  // Implementation would require checkout functionality for all files
end;

function TGitOperations.CleanWorkingDirectory(RemoveUntrackedFiles: Boolean): Boolean;
begin
  Result := False;
  // Implementation would require clean functionality
end;

function TGitOperations.GetFileChanges(const FilePath: string): string;
begin
  Result := '';
  // Implementation would require diff functionality
end;

function TGitOperations.GetStagedChanges: string;
begin
  Result := '';
  // Implementation would require diff functionality
end;

function TGitOperations.GetUnstagedChanges: string;
begin
  Result := '';
  // Implementation would require diff functionality
end;

function TGitOperations.GetDiffStats: TGitDiffStats;
begin
  FillChar(Result, SizeOf(Result), 0);
  // Implementation would require diff functionality
end;

function TGitOperations.SetConfig(const Key, Value: string; Global: Boolean): Boolean;
var
  Config: Pgit_config;
  ConfigPtr: PPgit_config;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  ConfigPtr := @Config;
  if Global then
  begin
    if git_config_open_global(ConfigPtr) = GIT_SUCCESS then
    try
      Result := git_config_set_string(Config, PAnsiChar(AnsiString(Key)), PAnsiChar(AnsiString(Value))) = GIT_SUCCESS;
    finally
      git_config_free(Config);
    end;
  end
  else
  begin
    if git_repository_config(ConfigPtr, FRepository.Repository) = GIT_SUCCESS then
    try
      Result := git_config_set_string(Config, PAnsiChar(AnsiString(Key)), PAnsiChar(AnsiString(Value))) = GIT_SUCCESS;
    finally
      git_config_free(Config);
    end;
  end;
end;

function TGitOperations.GetConfig(const Key: string; Global: Boolean): string;
var
  Config: Pgit_config;
  Value: PAnsiChar;
  ConfigPtr: PPgit_config;
begin
  Result := '';
  if not FRepository.IsOpen then Exit;

  ConfigPtr := @Config;
  if Global then
  begin
    if git_config_open_global(ConfigPtr) = GIT_SUCCESS then
    try
      if git_config_get_string(Config, PAnsiChar(AnsiString(Key)), Value) = GIT_SUCCESS then
        Result := string(Value);
    finally
      git_config_free(Config);
    end;
  end
  else
  begin
    if git_repository_config(ConfigPtr, FRepository.Repository) = GIT_SUCCESS then
    try
      if git_config_get_string(Config, PAnsiChar(AnsiString(Key)), Value) = GIT_SUCCESS then
        Result := string(Value);
    finally
      git_config_free(Config);
    end;
  end;
end;

function TGitOperations.SetUserInfo(const Name, Email: string; Global: Boolean): Boolean;
begin
  Result := SetConfig('user.name', Name, Global) and SetConfig('user.email', Email, Global);
end;

function TGitOperations.GetUserInfo(out Name, Email: string; Global: Boolean): Boolean;
begin
  Name := GetConfig('user.name', Global);
  Email := GetConfig('user.email', Global);
  Result := (Name <> '') and (Email <> '');
end;

// Implement GetCurrentBranch
function TGitOperations.GetCurrentBranch: string;
var
  Head: Pgit_reference;
  HeadPtr: PPgit_reference;
begin
  Result := '';
  if not FRepository.IsOpen then Exit;

  HeadPtr := @Head;
  if git_repository_head(HeadPtr, FRepository.Repository) = GIT_SUCCESS then
  try
    Result := string(PAnsiChar(git_reference_name(Head)));
    // Remove 'refs/heads/' prefix
    if Result.StartsWith('refs/heads/') then
      Result := Result.Substring(11);
  finally
    git_reference_free(Head);
  end;
end;

// Implement BranchExists
function TGitOperations.BranchExists(const BranchName: string): Boolean;
var
  Branch: Pgit_reference;
  BranchPtr: PPgit_reference;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  BranchPtr := @Branch;
  if git_reference_lookup(BranchPtr, FRepository.Repository,
    PAnsiChar(AnsiString('refs/heads/' + BranchName))) = GIT_SUCCESS then
  begin
    Result := True;
    git_reference_free(Branch);
  end;
end;

// Implement AddRemote
function TGitOperations.AddRemote(const Name, Url: string): Boolean;
var
  Remote: Pgit_remote;
  RemotePtr: PPgit_remote;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  RemotePtr := @Remote;
  if git_remote_new(RemotePtr, FRepository.Repository,
    PAnsiChar(AnsiString(Url)), PAnsiChar(AnsiString(Name))) = GIT_SUCCESS then
  begin
    Result := True;
    git_remote_free(Remote);
  end;
end;

// Implement FetchFromRemote
function TGitOperations.FetchFromRemote(const RemoteName: string): Boolean;
var
  Remote: Pgit_remote;
  RemotePtr: PPgit_remote;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  RemotePtr := @Remote;
  if git_remote_load(RemotePtr, FRepository.Repository, PAnsiChar(AnsiString(RemoteName))) = GIT_SUCCESS then
  try
    if git_remote_connect(Remote, GIT_DIR_FETCH) = GIT_SUCCESS then
    begin
      // Basic fetch - more complex implementation would handle progress callbacks
      Result := True;
      git_remote_disconnect(Remote);
    end;
  finally
    git_remote_free(Remote);
  end;
end;

// Implement GetLastCommit
function TGitOperations.GetLastCommit: TGitCommitInfo;
var
  Head: Pgit_reference;
  HeadPtr: PPgit_reference;
  OidStr: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FRepository.IsOpen then Exit;

  HeadPtr := @Head;
  if git_repository_head(HeadPtr, FRepository.Repository) = GIT_SUCCESS then
  try
    OidStr := git_oid_to_string(nil, 41, git_reference_oid(Head));
    Result := GetCommit(OidStr);
  finally
    git_reference_free(Head);
  end;
end;

// Implement GetCommit
function TGitOperations.GetCommit(const OidStr: string): TGitCommitInfo;
var
  Oid: git_oid;
  Commit: Pgit_commit;
  CommitPtr: PPgit_commit;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FRepository.IsOpen then Exit;

  CommitPtr := @Commit;
  if git_oid_fromstr(@Oid, PAnsiChar(AnsiString(OidStr))) = GIT_SUCCESS then
  begin
    if git_commit_lookup(CommitPtr, FRepository.Repository, @Oid) = GIT_SUCCESS then
    try
      Result.Oid := Oid;
      Result.ShortOid := Copy(OidStr, 1, 8);
      Result.Message := string(PAnsiChar(git_commit_message(Commit)));
      Result.Author := git_commit_author(Commit)^;
      Result.Committer := git_commit_committer(Commit)^;
      Result.DateTime := time_t__to__TDateTime(git_commit_time(Commit), git_commit_time_offset(Commit));
      Result.ParentCount := git_commit_parentcount(Commit);
    finally
      git_commit_free(Commit);
    end;
  end;
end;

// Implement GetCommitHistory
function TGitOperations.GetCommitHistory(MaxCount: Integer): TArray<TGitCommitInfo>;
var
  Walker: Pgit_revwalk;
  CommitOid: git_oid;
  Commit: Pgit_commit;
  CommitList: TList<TGitCommitInfo>;
  CommitInfo: TGitCommitInfo;
  Count: Integer;
  WalkerPtr: PPgit_revwalk;
  CommitPtr: PPgit_commit;
  Head: Pgit_reference;
  HeadPtr: PPgit_reference;
begin
  SetLength(Result, 0);
  if not FRepository.IsOpen then Exit;

  CommitList := TList<TGitCommitInfo>.Create;
  try
    WalkerPtr := @Walker;
    CommitPtr := @Commit;
    HeadPtr := @Head;

    if git_revwalk_new(WalkerPtr, FRepository.Repository) = GIT_SUCCESS then
    try
      git_revwalk_sorting(Walker, GIT_SORT_TIME);

      // Push HEAD
      if git_repository_head(HeadPtr, FRepository.Repository) = GIT_SUCCESS then
      try
        git_revwalk_push(Walker, git_reference_oid(Head));
      finally
        git_reference_free(Head);
      end;

      Count := 0;
      while (git_revwalk_next(@CommitOid, Walker) = GIT_SUCCESS) and (Count < MaxCount) do
      begin
        if git_commit_lookup(CommitPtr, FRepository.Repository, @CommitOid) = GIT_SUCCESS then
        try
          FillChar(CommitInfo, SizeOf(CommitInfo), 0);
          CommitInfo.Oid := CommitOid;
          CommitInfo.ShortOid := Copy(git_oid_to_string(nil, 41, @CommitOid), 1, 8);
          CommitInfo.Message := string(PAnsiChar(git_commit_message(Commit)));
          CommitInfo.Author := git_commit_author(Commit)^;
          CommitInfo.Committer := git_commit_committer(Commit)^;
          CommitInfo.DateTime := time_t__to__TDateTime(git_commit_time(Commit), git_commit_time_offset(Commit));
          CommitInfo.ParentCount := git_commit_parentcount(Commit);

          CommitList.Add(CommitInfo);
          Inc(Count);
        finally
          git_commit_free(Commit);
        end;
      end;
    finally
      git_revwalk_free(Walker);
    end;

    Result := CommitList.ToArray;
  finally
    CommitList.Free;
  end;
end;

// Implement CreateTag
function TGitOperations.CreateTag(const TagName, Message, Target: string): Boolean;
var
  TagOid: git_oid;
  TargetCommit: Pgit_commit;
  Author: Pgit_signature;
  CommitPtr: PPgit_commit;
  Head: Pgit_reference;
  HeadPtr: PPgit_reference;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  CommitPtr := @TargetCommit;
  HeadPtr := @Head;
  Author := CreateSignature('', '');
  try
    // If no target specified, use HEAD
    if Target = '' then
    begin
      if git_repository_head(HeadPtr, FRepository.Repository) = GIT_SUCCESS then
      try
        if git_commit_lookup(CommitPtr, FRepository.Repository, git_reference_oid(Head)) = GIT_SUCCESS then
        begin
          Result := git_tag_create(@TagOid, FRepository.Repository,
            PAnsiChar(AnsiString(TagName)), Pgit_object(TargetCommit), Author,
            PAnsiChar(AnsiString(Message)), 0) = GIT_SUCCESS;
        end;
      finally
        git_reference_free(Head);
      end;
    end;

    if Assigned(TargetCommit) then
      git_commit_free(TargetCommit);
  finally
    if Assigned(Author) then
      git_signature_free(Author);
  end;
end;

// Implement GetTags
function TGitOperations.GetTags: TArray<string>;
var
  TagNames: git_strarray;
  i: Integer;
begin
  SetLength(Result, 0);
  if not FRepository.IsOpen then Exit;

  if git_tag_list(@TagNames, FRepository.Repository) = GIT_SUCCESS then
  try
    SetLength(Result, TagNames.count);
    for i := 0 to TagNames.count - 1 do
    begin
      Result[i] := string(PAnsiChar(TagNames.strings[i]));
    end;
  finally
    git_strarray_free(@TagNames);
  end;
end;

// Implement DeleteTag
function TGitOperations.DeleteTag(const TagName: string): Boolean;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  Result := git_tag_delete(FRepository.Repository, PAnsiChar(AnsiString(TagName))) = GIT_SUCCESS;
end;

// Implement SetConfig and GetConfig (fix pointer usage)
function TGitOperations.SetConfig(const Key, Value: string; Global: Boolean): Boolean;
var
  Config: Pgit_config;
  ConfigPtr: PPgit_config;
begin
  Result := False;
  if not FRepository.IsOpen then Exit;

  ConfigPtr := @Config;
  if Global then
  begin
    if git_config_open_global(ConfigPtr) = GIT_SUCCESS then
    try
      Result := git_config_set_string(Config, PAnsiChar(AnsiString(Key)), PAnsiChar(AnsiString(Value))) = GIT_SUCCESS;
    finally
      git_config_free(Config);
    end;
  end
  else
  begin
    if git_repository_config(ConfigPtr, FRepository.Repository) = GIT_SUCCESS then
    try
      Result := git_config_set_string(Config, PAnsiChar(AnsiString(Key)), PAnsiChar(AnsiString(Value))) = GIT_SUCCESS;
    finally
      git_config_free(Config);
    end;
  end;
end;

function TGitOperations.GetConfig(const Key: string; Global: Boolean): string;
var
  Config: Pgit_config;
  Value: PAnsiChar;
  ConfigPtr: PPgit_config;
begin
  Result := '';
  if not FRepository.IsOpen then Exit;

  ConfigPtr := @Config;
  if Global then
  begin
    if git_config_open_global(ConfigPtr) = GIT_SUCCESS then
    try
      if git_config_get_string(Config, PAnsiChar(AnsiString(Key)), @Value) = GIT_SUCCESS then
        Result := string(Value);
    finally
      git_config_free(Config);
    end;
  end
  else
  begin
    if git_repository_config(ConfigPtr, FRepository.Repository) = GIT_SUCCESS then
    try
      if git_config_get_string(Config, PAnsiChar(AnsiString(Key)), @Value) = GIT_SUCCESS then
        Result := string(Value);
    finally
      git_config_free(Config);
    end;
  end;
end;

// Implement GetUserInfo and SetUserInfo
function TGitOperations.SetUserInfo(const Name, Email: string; Global: Boolean): Boolean;
begin
  Result := SetConfig('user.name', Name, Global) and SetConfig('user.email', Email, Global);
end;

function TGitOperations.GetUserInfo(out Name, Email: string; Global: Boolean): Boolean;
begin
  Name := GetConfig('user.name', Global);
  Email := GetConfig('user.email', Global);
  Result := (Name <> '') and (Email <> '');
end;

// Implement placeholder functions with basic functionality
function TGitOperations.GetBranches: TArray<TGitBranchInfo>;
begin
  // This would require iterating through references
  // For now, return empty array
  SetLength(Result, 0);
end;

function TGitOperations.RemoveRemote(const Name: string): Boolean;
begin
  // Remote removal is not directly supported in basic libgit2
  // Would need to modify config files
  Result := False;
end;

function TGitOperations.GetRemotes: TArray<TGitRemoteInfo>;
begin
  // This would require iterating through remotes
  // For now, return empty array
  SetLength(Result, 0);
end;

function TGitOperations.PushToRemote(const RemoteName, BranchName: string): Boolean;
begin
  // Push implementation would be complex and require push functionality
  Result := False;
end;

function TGitOperations.PullFromRemote(const RemoteName: string): Boolean;
begin
  // Pull = Fetch + Merge, complex implementation
  Result := False;
end;

function TGitOperations.SwitchBranch(const BranchName: string): Boolean;
begin
  // Branch switching requires checkout functionality
  Result := False;
end;

function TGitOperations.ResetSoft(const Target: string): Boolean;
begin
  // Reset implementation would require reset functionality
  Result := False;
end;

function TGitOperations.ResetMixed(const Target: string): Boolean;
begin
  // Reset implementation would require reset functionality
  Result := False;
end;

function TGitOperations.ResetHard(const Target: string): Boolean;
begin
  // Reset implementation would require reset functionality
  Result := False;
end;

function TGitOperations.CheckoutFile(const FilePath: string): Boolean;
begin
  // Checkout implementation would require checkout functionality
  Result := False;
end;

function TGitOperations.CheckoutFiles(const FilePaths: TArray<string>): Boolean;
begin
  // Checkout implementation would require checkout functionality
  Result := False;
end;

function TGitOperations.DiscardChanges(const FilePath: string): Boolean;
begin
  Result := CheckoutFile(FilePath);
end;

function TGitOperations.DiscardAllChanges: Boolean;
begin
  // Would require checkout functionality for all files
  Result := False;
end;

function TGitOperations.CleanWorkingDirectory(RemoveUntrackedFiles: Boolean): Boolean;
begin
  // Clean implementation would require clean functionality
  Result := False;
end;

function TGitOperations.GetFileChanges(const FilePath: string): string;
begin
  // Diff implementation would require diff functionality
  Result := '';
end;

function TGitOperations.GetStagedChanges: string;
begin
  // Diff implementation would require diff functionality
  Result := '';
end;

function TGitOperations.GetUnstagedChanges: string;
begin
  // Diff implementation would require diff functionality
  Result := '';
end;

function TGitOperations.GetDiffStats: TGitDiffStats;
begin
  // Diff implementation would require diff functionality
  FillChar(Result, SizeOf(Result), 0);
end;

end.
