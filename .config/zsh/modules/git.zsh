# =============================================================================
# Git Workflow Functions
# =============================================================================

fetch() {
    command git fetch
}

push() {
    command git push -f
}

list() {
    command git branch
}

pull() {
    command git pull
}

clean() {
    command git branch --merged | grep -Ev "(^\*|${BASE_BRANCH})" | xargs git branch -d
    command git remote prune origin
    command git gc --prune
}

checkout() {
    command git checkout "$@"
    rebase "${BASE_BRANCH}"
}

base() {
    if [[ -z "${BASE_BRANCH}" ]]; then
        echo "BASE_BRANCH not set"
    elif [[ -z "$1" ]]; then
        command git checkout "${BASE_BRANCH}"
        command git reset --hard "${BASE_BRANCH}"
        pull
    else
        export BASE_BRANCH="$1"
        base
    fi
}

master() {
    export BASE_BRANCH="master"
    base
}

main() {
    export BASE_BRANCH="main"
    base
}

amend() {
    command git add .
    if [[ -z "$*" ]]; then
        command git commit --amend --no-edit
    else
        command git commit --amend -m "$*"
    fi
    command git push -f
}

commit() {
    command git add .
    command git commit -m "$*"
}

branch() {
    command git checkout "${BASE_BRANCH}"
    command git reset --hard "${BASE_BRANCH}"
    pull
    command git checkout -b "$@"
    rebase "${BASE_BRANCH}"
    push
}

rebase() {
    case "$1" in
        --continue|continue)
            command git add .
            command git rebase --continue
            ;;
        --abort|abort)
            command git rebase --abort
            ;;
        "")
            command git rebase "origin/${BASE_BRANCH}"
            ;;
        *)
            command git rebase "origin/$1"
            ;;
    esac
}

# Consolidated from restore/revert/reset — all did the same thing
restore() {
    command git checkout "origin/${BASE_BRANCH}" -- "$@"
}
alias revert='restore'
alias reset='restore'

nuke() {
    command git clean -dnfX
    echo -n "Are you sure you want to delete those files? (y/n) "
    while read -k 1 response; do
        echo
        case "$response" in
            [yY])
                command git clean -dfX
                return
                ;;
            [nN])
                echo "Aborting"
                return
                ;;
            *)
                echo "Only y or n"
                echo -n "Are you sure you want to delete those files? (y/n) "
                ;;
        esac
    done
}

pr() {
    command gh pr create -d --fill
}
