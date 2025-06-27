# Makefile for managing work folder syncing

WORK_DIR := work
SYNC_DIR := work_latest
MAX_FOLDERS := 5

.PHONY: sync-work commit-work clean-sync help

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

sync-work: ## Sync the latest work folders to work_latest/
	@echo "🔄 Syncing latest $(MAX_FOLDERS) work folders..."
	@./sync_latest_work.sh $(WORK_DIR)

commit-work: sync-work ## Sync work folders and commit them
	@echo "📝 Adding synced work folders to git..."
	@git add $(SYNC_DIR)
	@git status --porcelain | grep -q "^A.*$(SYNC_DIR)" && \
		git commit -m "Update latest work folders ($(shell date '+%Y-%m-%d %H:%M'))" || \
		echo "ℹ️  No changes to commit"

push-work: commit-work ## Sync, commit, and push work folders
	@echo "🚀 Pushing to remote..."
	@git push

clean-sync: ## Clean the work_latest directory
	@echo "🧹 Cleaning $(SYNC_DIR)..."
	@rm -rf $(SYNC_DIR)/*
	@echo "✅ Cleaned"

status: ## Show status of work folders
	@echo "📊 Work folder status:"
	@echo "Total work folders: $(shell find $(WORK_DIR) -maxdepth 2 -type d -name '[0-9a-f][0-9a-f]' 2>/dev/null | wc -l)"
	@echo "Latest 5 folders:"
	@find $(WORK_DIR) -maxdepth 2 -type d -name '[0-9a-f][0-9a-f]' -printf '%T@ %p\n' 2>/dev/null | \
		sort -nr | head -n 5 | while read timestamp folder; do \
			echo "  - $$folder ($(shell date -d @$$timestamp '+%Y-%m-%d %H:%M'))"; \
		done || echo "  No work folders found"

failed: ## Show only failed work folders from latest 10
	@echo "❌ Recent failed tasks:"
	@find $(WORK_DIR) -maxdepth 2 -name '.exitcode' -printf '%T@ %h\n' 2>/dev/null | \
		sort -nr | head -n 10 | while read timestamp folder; do \
			exitcode=$$(cat "$$folder/.exitcode" 2>/dev/null); \
			if [[ "$$exitcode" != "0" ]]; then \
				process=$$(grep 'NEXTFLOW TASK' "$$folder/.command.run" 2>/dev/null | cut -d':' -f2 | xargs || echo 'Unknown'); \
				echo "  - $$folder (exit: $$exitcode, process: $$process)"; \
			fi; \
		done || echo "  No failed tasks found"