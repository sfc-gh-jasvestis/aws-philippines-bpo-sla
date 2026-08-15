-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Service Level Optimization & SLA Drift Detection
-- ============================================================================
USE DATABASE SLA_OPERATIONS;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.SLA_OPERATIONS_AGENT
  COMMENT = 'Service Level Optimization & SLA Drift Detection AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'SLA_OPERATIONS.APP.SLA_OPERATIONS_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'SLA_OPERATIONS.SEARCH.SLA_CONTRACT_SEARCH', TOOL_DESCRIPTION => 'Search documents for BPO & IT Services information')
  )
  SYSTEM_PROMPT = 'You are the SLA Operations Agent for a Philippine BPO managing 200+ SLA metrics across 42 enterprise clients with combined contract value of ₱4.2B.';
