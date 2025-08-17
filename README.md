GitForDelphi - Delphi bindings to [libgit2](https://github.com/libgit2/libgit2)
=================================

The original work for GitForDelphi allows you to work with git repositories from within your Delphi code, with the only dependencies being the uGitForDelphi.pas source file and the libgit2 DLL.

It was announced wrapper classes are to be developed in the future for easier Delphi-like calling. This repository clone extends the original work with two more units. These units wrap the original work for the announcaed easier Delphi-like access.

Current status
--------------

I added the long awaited wrapper class, `TGitRepository` to give a nicer Delphi-like interface to working with repositories. Additionally `TGitOperations` will allow easier Delphi-like operations to be executed.

Unit tests have not been added just yet to this repository. You are welcome to help contribute.

Usage example:

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


### pre-built libgit2 DLL:

git2.dll built from Visual C++ 2010 Express is in the `binary` branch,
you can use it while in the master branch like this

    git checkout origin/binary -- tests/git2.dll; git reset tests/git2.dll

See `LIBGIT2_sha` file for the libgit2 commit that the dll and code are currently based on.

License
=======

MIT. See LICENSE file.
